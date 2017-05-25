# Additional user methods in parallel with Devise -- all pertaining to call list
class UsersController < ApplicationController
  before_action :retrieve_patients, only: [:add_patient, :remove_patient]
  before_action :confirm_admin_user, only: [:new, :index]
  before_action :find_user, only: [:update, :edit, :destroy]

  rescue_from Mongoid::Errors::DocumentNotFound, with: -> { head :bad_request }

  def index
    @users = User.all
  end

  def edit
  end

  # TODO test, also refactor search
  def search
    if params[:search].empty?
      @results = User.all
      respond_to { |format| format.js }
    else
      @results = User.search_users params[:search]
      respond_to { |format| format.js }
    end
  end

  # TODO test
  def toggle_lock
    @user = User.find(params[:user_id])
    if @user == current_user
      redirect_to edit_user_path @user
    else
      if @user.access_locked?
        flash[:notice] = 'Successfully unlocked ' + @user.email
        @user.unlock_access!
      else
        flash[:notice] = 'Successfully locked ' + @user.email
        @user.lock_access!
      end
      redirect_to edit_user_path @user
    end
    # respond_to { |format| format.js }
  end

  #TODO test
  def reset_password
    @user = User.find(params[:user_id])

    # TODO doesn't work in dev
    @user.send_reset_password_instructions

    flash[:notice] = 'Successfully sent password reset instructions to ' + @user.email
    redirect_to edit_user_path @user
  end

  # TODO test
  def update
    if @user.update_attributes user_params
      flash[:notice] = 'Successfully updated user details'
    else
      flash[:alert] = 'Error saving user details'
    end
    redirect_to users_path
  end


  def create
    raise RuntimeError('Permission Denied') unless current_user.admin?
    @user = User.new(user_params)
    hex = SecureRandom.urlsafe_base64
    @user.password, @user.password_confirmation = hex
    if @user.save
      flash[:notice] = 'User created!'
      redirect_to session.delete(:return_to)
    else
      # if validation errors, render creation page with error msgs
      render 'new'
    end
  end

  def new
    @user = User.new
    session[:return_to] ||= request.referer
  end

  def add_patient
    current_user.add_patient @patient
    respond_to do |format|
      format.js { render template: 'users/refresh_patients', layout: false }
    end
  end

  def remove_patient
    current_user.remove_patient @patient
    respond_to do |format|
      format.js { render template: 'users/refresh_patients', layout: false }
    end
  end

  def reorder_call_list
    # TODO: fail if anything is not a BSON id
    current_user.reorder_call_list params[:order] # TODO: adjust to payload
    # respond_to { |format| format.js }
    head :ok
  end

  private

  # copied from DashboardsController
  def searched_for_name?(query)
    /[a-z]/i.match query
  end

  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :_role)
  end

  def retrieve_patients
    @patient = Patient.find params[:id]
    @urgent_patient = Patient.where(urgent_flag: true)
  end
end
