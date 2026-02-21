class Meeting < ApplicationRecord
  has_many :agenda_sections, -> { order(:number) }, dependent: :destroy
  has_many :agenda_items, through: :agenda_sections

  enum :meeting_type, {
    regular: "regular",
    special: "special",
    caucus: "caucus"
  }

  validates :date, presence: true
  validates :meeting_type, presence: true
  validates :date, uniqueness: { scope: :meeting_type }

  scope :chronological, -> { order(date: :desc) }

  def display_name
    "#{meeting_type.titleize} Meeting - #{date.strftime('%B %-d, %Y')}"
  end
end
