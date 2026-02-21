class AgendaItemTag < ApplicationRecord
  belongs_to :agenda_item
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :agenda_item_id }
end
