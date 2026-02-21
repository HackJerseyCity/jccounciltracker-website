class AgendaSection < ApplicationRecord
  belongs_to :meeting
  has_many :agenda_items, -> { order(:position) }, dependent: :destroy

  enum :section_type, {
    ordinance_first_reading: "ordinance_first_reading",
    ordinance_second_reading: "ordinance_second_reading",
    resolutions: "resolutions",
    petitions_communications: "petitions_communications",
    reports_of_directors: "reports_of_directors",
    claims: "claims",
    regular_meeting: "regular_meeting",
    reception_bid: "reception_bid",
    deferred: "deferred",
    adjournment: "adjournment"
  }

  validates :number, presence: true, uniqueness: { scope: :meeting_id }
  validates :title, presence: true
  validates :section_type, presence: true
end
