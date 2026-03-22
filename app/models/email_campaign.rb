class EmailCampaign < ApplicationRecord
  belongs_to :user
  has_many :email_deliveries, dependent: :destroy
  has_rich_text :body

  CAMPAIGN_TYPES = {
    "council_updates" => { label: "Council Updates", preference: :email_council_updates },
    "blog" => { label: "Blog", preference: :email_blog },
    "marketing" => { label: "Marketing", preference: :email_marketing }
  }.freeze

  validates :title, presence: true
  validates :body, presence: true
  validates :campaign_type, inclusion: { in: CAMPAIGN_TYPES.keys }

  scope :chronological, -> { order(created_at: :desc) }
  scope :draft, -> { where(status: "draft") }
  scope :sent, -> { where(status: "sent") }

  def draft?
    status == "draft"
  end

  def sending?
    status == "sending"
  end

  def sent?
    status == "sent"
  end

  def send_campaign!
    raise "Campaign already sent" unless draft?

    update!(status: "sending")
    SendCampaignJob.perform_later(self)
  end

  def preference_column
    CAMPAIGN_TYPES.dig(campaign_type, :preference)
  end

  def type_label
    CAMPAIGN_TYPES.dig(campaign_type, :label) || campaign_type.titleize
  end

  def subscribed_users
    col = preference_column
    col ? User.where(col => true) : User.all
  end

  def recipient_count
    subscribed_users.count
  end
end
