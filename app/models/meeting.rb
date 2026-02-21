class Meeting < ApplicationRecord
  has_many :agenda_versions, -> { order(:version_number) }, dependent: :destroy

  enum :meeting_type, {
    regular: "regular",
    special: "special",
    caucus: "caucus"
  }

  validates :date, presence: true
  validates :meeting_type, presence: true
  validates :date, uniqueness: { scope: :meeting_type }

  scope :chronological, -> { order(date: :desc) }

  def current_version
    agenda_versions.last
  end

  def version(number)
    agenda_versions.find_by(version_number: number)
  end

  def agenda_sections
    current_version&.agenda_sections || AgendaSection.none
  end

  def agenda_items
    current_version&.agenda_items || AgendaItem.none
  end

  def agenda_pages
    current_version&.agenda_pages
  end

  def versions_count
    agenda_versions.size
  end

  def minutes_imported?
    agenda_items.joins(:votes).exists?
  end

  def display_name
    "#{meeting_type.titleize} Meeting - #{date.strftime('%B %-d, %Y')}"
  end
end
