require 'test_helper'

class ReportingPatientTest < ActiveSupport::TestCase
  before do
    @user = create :user

    # we'll create five patients with reached calls this month
    (1..5).each do |patient_number|
      patient = create(
        :patient,
        line: 'VA',
        other_phone: '111-222-3333',
        other_contact: 'Yolo'
      )

      # reached calls this month
      (1..5).each do |call_number|
        Timecop.freeze(Time.now - call_number.days) do
          create(
            :call,
            patient: patient,
            status: 'Reached patient'
          )
        end
      end

      # not reached calls this month
      (1..5).each do |call_number|
        Timecop.freeze(Time.now - call_number.days) do
          create(
            :call,
            patient: patient,
            status: 'Left voicemail'
          )
        end
      end
    end

      # we'll create 5 patients with calls this year
    (1..5).each do |patient_number|
      patient = create(
        :patient,
        line: 'VA',
        other_phone: '111-222-3333',
        other_contact: 'Yolo'
      )

        # calls this year
      (1..5).each do |call_number|
        Timecop.freeze(Time.now - call_number.months - call_number.days) do
          create(
            :call,
            patient: patient,
            status: 'Reached patient'
          )
        end
      end
    end
  end

  describe '#contacted_for_line' do
    it 'should return the correct amount of contacted patients for the timeframe' do
      month_num_contacted = Reporting::Patient.contacted_for_line('VA', Time.now - 1.month, Time.now)
      assert_equal 5, month_num_contacted

      year_num_contacted = Reporting::Patient.contacted_for_line('VA', Time.now - 1.year, Time.now)
      # require 'pry'
      # binding.pry
      assert_equal 10, year_num_contacted
    end
  end
end
