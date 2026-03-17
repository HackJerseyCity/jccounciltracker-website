class BlogPost < ApplicationRecord
  belongs_to :user
  alias_method :author, :user

  has_rich_text :body

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
  validates :body, presence: true

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current).order(published_at: :desc) }
  scope :draft, -> { where(published_at: nil) }
  scope :chronological, -> { order(created_at: :desc) }

  def published?
    published_at.present? && published_at <= Time.current
  end

  def draft?
    !published?
  end

  def publish!
    update!(published_at: Time.current) if draft?
  end

  def unpublish!
    update!(published_at: nil) if published?
  end

  def to_param
    slug
  end

  private

  def generate_slug
    base_slug = title.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/[\s]+/, "-").gsub(/-+/, "-").strip
    self.slug = base_slug

    counter = 1
    while BlogPost.where(slug: self.slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
