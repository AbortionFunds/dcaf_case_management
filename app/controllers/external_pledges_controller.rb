# Create a pledge. Not currently utilized
class ExternalPledgesController < ApplicationController
  before_action :find_patient, only: [:create]
  before_action :find_pledge, only: [:update]
  rescue_from Mongoid::Errors::DocumentNotFound,
              with: -> { head :bad_request }

  def create
    pledge = @patient.external_pledges.new external_pledge_params
    pledge.created_by = current_user

    if pledge.save
      respond_to { |format| format.js }
    else
      head :bad_request
    end
  end

  def update
    if @pledge.update_attributes external_pledge_params
      respond_to { |format| format.js }
    else
      head :bad_request
    end
  end

  def destroy
    @pledge.update active: false
    respond_to { |format| format.js }
  end

  private

  def external_pledge_params
    params.require(:external_pledge).permit(:source, :amount)
  end

  def find_patient
    @patient = Patient.find params[:patient_id]
  end

  def find_pledge
    find_patient
    @pledge = @patient.external_pledges.find params[:id]
  end
end
