class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :stars, dependent: :destroy
  has_many :blog_posts, dependent: :destroy
  has_many :admin_audit_logs, dependent: :destroy

  def starred?(item)
    stars.exists?(starrable: item)
  end

  enum :role, { user: 0, content_admin: 1, site_admin: 2 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true

  def admin?
    site_admin? || content_admin?
  end
end
