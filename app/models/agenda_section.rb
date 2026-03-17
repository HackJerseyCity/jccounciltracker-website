class AgendaSection < ApplicationRecord
  belongs_to :agenda_version
  has_many :agenda_items, -> { order(:position) }, dependent: :destroy

  delegate :meeting, to: :agenda_version

  enum :section_type, {
    ordinance_first_reading: "ordinance_first_reading",
    ordinance_second_reading: "ordinance_second_reading",
    public_request_for_hearing: "public_request_for_hearing",
    petitions_communications: "petitions_communications",
    reports_of_directors: "reports_of_directors",
    resolutions: "resolutions"
  }

  validates :number, presence: true
  validates :title, presence: true
  validates :section_type, presence: true
end
