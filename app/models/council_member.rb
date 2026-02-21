class CouncilMember < ApplicationRecord
  has_many :votes, dependent: :destroy
  has_many :voted_agenda_items, through: :votes, source: :agenda_item

  enum :seat, {
    ward_a: "ward_a", ward_b: "ward_b", ward_c: "ward_c",
    ward_d: "ward_d", ward_e: "ward_e", ward_f: "ward_f",
    at_large: "at_large"
  }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :seat, presence: true
  validates :term_start, presence: true
  validate :term_end_after_start

  scope :current, -> { where(term_end: nil).or(where("term_end >= ?", Date.current)) }
  scope :alphabetical, -> { order(:last_name, :first_name) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def display_name
    "#{full_name} (#{seat.titleize})"
  end

  def seat_label
    seat.starts_with?("ward") ? "Ward #{seat[-1].upcase}" : "At Large"
  end

  def current?
    term_end.nil? || term_end >= Date.current
  end

  private

  def term_end_after_start
    if term_end.present? && term_start.present? && term_end < term_start
      errors.add(:term_end, "must be after term start")
    end
  end
end
