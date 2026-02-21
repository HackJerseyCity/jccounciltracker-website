class AgendaItem < ApplicationRecord
  VALID_RESULTS = %w[introduced approved adopted carried withdrawn defeated tabled amended].freeze

  belongs_to :agenda_section
  has_one :agenda_version, through: :agenda_section
  has_one :meeting, through: :agenda_version
  has_many :votes, dependent: :destroy
  has_many :agenda_item_tags, dependent: :destroy
  has_many :tags, through: :agenda_item_tags

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
  validates :result, inclusion: { in: VALID_RESULTS }, allow_nil: true

  scope :voted_on, -> { where.not(result: nil) }
end
