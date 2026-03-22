class EmailCampaign < ApplicationRecord
  belongs_to :user
  has_many :email_deliveries, dependent: :destroy
  has_rich_text :body

  validates :title, presence: true
  validates :body, presence: true

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

  def recipient_count
    User.where(email_notifications: true).count
  end
end
