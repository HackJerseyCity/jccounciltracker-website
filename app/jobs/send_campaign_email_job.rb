class SendCampaignEmailJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(delivery)
    return if delivery.status == "sent"

    CampaignMailer.campaign_email(delivery.user, delivery.email_campaign).deliver_now
    delivery.update!(status: "sent", sent_at: Time.current)
  rescue => e
    delivery.update!(status: "failed")
    raise
  end
end
