class CreateAgendaItemTags < ActiveRecord::Migration[8.1]
  def change
    create_table :agenda_item_tags do |t|
      t.references :agenda_item, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :agenda_item_tags, [ :agenda_item_id, :tag_id ], unique: true
  end
end
