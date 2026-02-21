class Vote < ApplicationRecord
  belongs_to :agenda_item
  belongs_to :council_member

  enum :position, { aye: "aye", nay: "nay", abstain: "abstain", absent: "absent" }

  validates :position, presence: true
  validates :council_member_id, uniqueness: { scope: :agenda_item_id }
end
