class CreateMeetingsAgendaSectionsAndAgendaItems < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.date :date, null: false
      t.string :meeting_type, null: false
      t.integer :agenda_pages

      t.timestamps
    end

    add_index :meetings, [ :date, :meeting_type ], unique: true

    create_table :agenda_sections do |t|
      t.references :meeting, null: false, foreign_key: true
      t.integer :number, null: false
      t.string :title, null: false
      t.string :section_type, null: false

      t.timestamps
    end

    add_index :agenda_sections, [ :meeting_id, :number ], unique: true

    create_table :agenda_items do |t|
      t.references :agenda_section, null: false, foreign_key: true
      t.string :item_number, null: false
      t.text :title, null: false
      t.integer :page_start
      t.integer :page_end
      t.string :file_number
      t.string :item_type, null: false
      t.string :url
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :agenda_items, [ :agenda_section_id, :item_number ], unique: true
  end
end
