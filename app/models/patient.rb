# Object representing core patient information and demographic data.

class Patient
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Enum
  include Mongoid::History::Trackable
  include Mongoid::Userstamp
  include StatusHelper

  include LastMenstrualPeriodHelper

  include Urgency
  include Callable
  include Notetakeable
  include Searchable
  include AttributeDisplayable
  include Pledgeable

  LINES.each do |line|
    scope line.downcase.to_sym, -> { where(:_line.in => [line]) }
  end

  before_validation :clean_fields
  after_create :initialize_fulfillment

  # Relationships
  has_and_belongs_to_many :users, inverse_of: :patients
  belongs_to :clinic
  # embeds_one :pregnancy
  embeds_one :fulfillment
  embeds_many :calls
  embeds_many :external_pledges
  embeds_many :notes

  # Enable mass posting in forms
  # accepts_nested_attributes_for :pregnancy
  accepts_nested_attributes_for :fulfillment

  # Fields
  # Searchable info
  field :name, type: String # strip
  field :primary_phone, type: String
  field :other_contact, type: String
  field :other_phone, type: String
  field :other_contact_relationship, type: String
  field :identifier, type: String

  # Contact-related info
  enum :voicemail_preference, [:not_specified, :no, :yes]
  enum :line, [:DC, :MD, :VA] # See config/initializers/lines.rb. TODO: Env var.
  field :spanish, type: Boolean
  field :initial_call_date, type: Date
  field :urgent_flag, type: Boolean
  field :last_menstrual_period_weeks, type: Integer
  field :last_menstrual_period_days, type: Integer

  # Program analysis related or NAF eligibility related info
  field :age, type: Integer
  field :city, type: String
  field :state, type: String
  field :zip, type: String
  field :county, type: String
  field :race_ethnicity, type: String
  field :employment_status, type: String
  field :household_size_children, type: Integer
  field :household_size_adults, type: Integer
  field :insurance, type: String
  field :income, type: String
  field :special_circumstances, type: Array, default: []
  field :referred_by, type: String

  # Status and pledge related fields
  field :appointment_date, type: Date
  field :patient_contribution, type: Integer
  field :naf_pledge, type: Integer
  field :dcaf_soft_pledge, type: Integer
  field :pledge_sent, type: Boolean
  field :resolved_without_dcaf, type: Boolean

  # Indices
  index({ primary_phone: 1 }, unique: true)
  index(other_contact_phone: 1)
  index(name: 1)
  index(other_contact: 1)
  index(urgent_flag: 1)
  index(_line: 1)
  index(identifier: 1)

  # Validations
  validates :name,
            :primary_phone,
            :initial_call_date,
            :created_by_id,
            :line,
            presence: true
  validates :primary_phone, format: /\d{10}/, length: { is: 10 }, uniqueness: true
  validates :other_phone, format: /\d{10}/,
                          length: { is: 10 },
                          allow_blank: true
  validates :appointment_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/,
                               allow_blank: true

  validate :confirm_appointment_after_initial_call

  validate :pledge_sent, :pledge_info_presence, if: :updating_pledge_sent?

  # validates_associated :pregnancy
  validates_associated :fulfillment
  before_save :save_identifier

  # some validation of presence of at least one pregnancy
  # some validation of only one active pregnancy at a time

  # History and auditing
  track_history on: fields.keys + [:updated_by_id],
                version_field: :version,
                track_create: true,
                track_update: true,
                track_destroy: true
  mongoid_userstamp user_model: 'User'

  # Methods
  def self.pledged_status_summary(num_days = 7)
    # return pledge totals for patients with appts in the next num_days
    # TODO move to Pledge class, when implemented?
    outstanding_pledges = 0
    sent_total = 0
    Patient.where(:appointment_date.lte => Date.today + num_days).each do |patient|
      if patient.pledge_sent
        sent_total += (patient.dcaf_soft_pledge || 0)
      else
        outstanding_pledges += (patient.dcaf_soft_pledge || 0)
      end
    end
    { pledged: outstanding_pledges, sent: sent_total }
  end

  # TODO: reimplement once pledge is available
  def most_recent_pledge_display_date
   display_date = most_recent_pledge.try(:sent).to_s
   display_date
  end

  # TODO: reimplement once pledge is available
  def most_recent_pledge
   pledges.order('created_at DESC').limit(1).first
  end

  def save_identifier
    self.identifier = "#{line[0]}#{primary_phone[-5]}-#{primary_phone[-4..-1]}"
  end

  def assemble_audit_trails
    history_tracks.sort_by(&:created_at)
                  .reverse
  end

  private

  def confirm_appointment_after_initial_call
    if appointment_date.present? && initial_call_date > appointment_date
      errors.add(:appointment_date, 'must be after date of initial call')
    end
  end

  def clean_fields
    primary_phone.gsub!(/\D/, '') if primary_phone
    other_phone.gsub!(/\D/, '') if other_phone
    name.strip! if name
    other_contact.strip! if other_contact
    other_contact_relationship.strip! if other_contact_relationship
  end

  def initialize_fulfillment
    build_fulfillment(created_by_id: created_by_id).save
  end
end
