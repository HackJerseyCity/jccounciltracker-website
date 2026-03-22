class CampaignMailer < ApplicationMailer
  def campaign_email(user, campaign)
    @user = user
    @campaign = campaign
    @unsubscribe_url = unsubscribe_url_for(user)

    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    mail(to: user.email_address, subject: campaign.title)
  end
end
