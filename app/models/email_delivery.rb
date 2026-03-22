class EmailDelivery < ApplicationRecord
  belongs_to :email_campaign
  belongs_to :user

  scope :pending, -> { where(status: "pending") }
  scope :sent, -> { where(status: "sent") }
  scope :failed, -> { where(status: "failed") }
end
