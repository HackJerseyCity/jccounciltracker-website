class AgendaItem < ApplicationRecord
  belongs_to :agenda_section
  has_one :meeting, through: :agenda_section

  enum :item_type, {
    ordinance: "ordinance",
    resolution: "resolution",
    claims: "claims",
    other: "other"
  }

  validates :item_number, presence: true, uniqueness: { scope: :agenda_section_id }
  validates :title, presence: true
  validates :item_type, presence: true
  validates :position, presence: true
end
