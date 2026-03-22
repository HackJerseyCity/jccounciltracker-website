class UnsubscribesController < ApplicationController
  allow_unauthenticated_access

  before_action :set_user_from_token

  def show
  end

  def update
    preference_params = params.permit(*User::EMAIL_PREFERENCES.keys.map(&:to_s))

    updates = {}
    User::EMAIL_PREFERENCES.each_key do |pref|
      updates[pref] = preference_params[pref.to_s] == "1"
    end

    @user.update!(updates)
    @saved = true
    render :show
  end

  def unsubscribe_all
    updates = User::EMAIL_PREFERENCES.keys.index_with { false }
    @user.update!(updates)
    @saved = true
    @unsubscribed_all = true
    render :show
  end

  private

  def set_user_from_token
    user_id = Rails.application.message_verifier(:unsubscribe).verify(params[:token])
    @user = User.find(user_id)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to root_path, alert: "Invalid or expired link. Please log in to manage your email preferences."
  end
end
