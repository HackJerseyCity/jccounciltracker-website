class AgendaVersion < ApplicationRecord
  belongs_to :meeting
  has_many :agenda_sections, -> { order(:number) }, dependent: :destroy
  has_many :agenda_items, through: :agenda_sections

  enum :status, { draft: "draft", published: "published" }

  validates :version_number, presence: true,
    numericality: { only_integer: true, greater_than: 0 },
    uniqueness: { scope: :meeting_id }
  validates :status, presence: true

  scope :published, -> { where(status: :published) }
  scope :draft, -> { where(status: :draft) }

  def publish!
    update!(status: :published)
  end

  def unpublish!
    update!(status: :draft)
  end

  def latest?
    version_number == meeting.agenda_versions.maximum(:version_number)
  end

  def display_label
    label = "Version #{version_number} (uploaded #{created_at.strftime('%b %-d')})"
    label += " - Latest" if latest?
    label
  end
end
