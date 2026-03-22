class UserMailer < ApplicationMailer
  def welcome(user)
    @user = user
    mail(to: user.email_address, subject: "Welcome to CouncilTracker")
  end
end
