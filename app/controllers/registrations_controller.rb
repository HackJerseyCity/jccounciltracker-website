class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_invitation
  before_action :validate_invitation

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = @invitation.role

    if @user.save
      @invitation.accept!(@user)
      UserMailer.welcome(@user).deliver_later
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to CouncilTracker!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.find_by(token: params[:token])
  end

  def validate_invitation
    if @invitation.nil?
      redirect_to root_path, alert: "Invalid invitation link."
    elsif @invitation.accepted?
      redirect_to root_path, alert: "This invitation has already been used."
    elsif @invitation.expired?
      redirect_to root_path, alert: "This invitation has expired."
    end
  end

  def registration_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
  end
end
