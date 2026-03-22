class SignupsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_signup_path, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(signup_params)
    @user.role = :user

    if @user.save
      UserMailer.welcome(@user).deliver_later
      start_new_session_for @user
      redirect_to root_path, notice: "Welcome to CouncilTracker!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def signup_params
    params.expect(user: [ :name, :email_address, :password, :password_confirmation ])
  end
end
