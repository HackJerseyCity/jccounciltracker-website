class ApplicationMailer < ActionMailer::Base
  default from: "Jersey City Council Tracker <notifications@jccounciltracker.com>"
  layout "mailer"

  private

  def preferences_url_for(user)
    token = Rails.application.message_verifier(:unsubscribe).generate(user.id, expires_in: 30.days)
    unsubscribe_url(token: token)
  end

  def set_preferences_link(user)
    @preferences_url = preferences_url_for(user)
  end
end
