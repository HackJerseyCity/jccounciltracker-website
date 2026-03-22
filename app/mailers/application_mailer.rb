class ApplicationMailer < ActionMailer::Base
  default from: "CouncilTracker <notifications@jccounciltracker.com>"
  layout "mailer"

  private

  def unsubscribe_url_for(user)
    token = Rails.application.message_verifier(:unsubscribe).generate(user.id, expires_in: 30.days)
    unsubscribe_url(token: token)
  end
end
