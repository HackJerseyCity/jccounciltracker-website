class SendCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign)
    users = campaign.subscribed_users

    users.find_each do |user|
      campaign.email_deliveries.find_or_create_by!(user: user)
    end

    campaign.email_deliveries.pending.find_each do |delivery|
      SendCampaignEmailJob.perform_later(delivery)
    end

    campaign.update!(status: "sent", sent_at: Time.current, sent_count: campaign.email_deliveries.count)
  end
end
