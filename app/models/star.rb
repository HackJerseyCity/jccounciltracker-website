class Star < ApplicationRecord
  belongs_to :user
  belongs_to :starrable, polymorphic: true

  validates :user_id, uniqueness: { scope: [ :starrable_type, :starrable_id ] }
end
