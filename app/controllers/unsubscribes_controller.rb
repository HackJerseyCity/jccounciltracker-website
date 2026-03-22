class UnsubscribesController < ApplicationController
  allow_unauthenticated_access

  before_action :set_user_from_token

  def show
  end

  def create
    @user.update!(email_notifications: false)
  end

  private

  def set_user_from_token
    user_id = Rails.application.message_verifier(:unsubscribe).verify(params[:token])
    @user = User.find(user_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, alert: "Invalid or expired unsubscribe link."
  end
end
