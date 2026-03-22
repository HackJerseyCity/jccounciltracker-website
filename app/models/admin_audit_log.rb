class AdminAuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :target, polymorphic: true, optional: true

  validates :action, presence: true

  serialize :metadata, coder: JSON

  scope :recent, -> { order(created_at: :desc) }

  def self.log(action:, user: Current.user, target: nil, metadata: {})
    create!(
      action: action,
      user: user,
      target_type: target&.class&.name,
      target_id: target&.id,
      metadata: metadata.presence
    )
  rescue => e
    Rails.logger.error("Audit log failed: #{e.message}")
  end
end
