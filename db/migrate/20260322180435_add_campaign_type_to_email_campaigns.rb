class AddCampaignTypeToEmailCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :email_campaigns, :campaign_type, :string, null: false, default: "council_updates"
  end
end
