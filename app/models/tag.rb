class Tag < ApplicationRecord
  has_many :agenda_item_tags, dependent: :destroy
  has_many :agenda_items, through: :agenda_item_tags

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  normalizes :name, with: ->(name) { name.strip }

  scope :search, ->(query) { where("LOWER(name) LIKE ?", "%#{query.downcase}%") }
  scope :alphabetical, -> { order(Arel.sql("LOWER(name)")) }
end
