class AddAgendaVersioning < ActiveRecord::Migration[8.1]
  def up
    # Phase A: Create agenda_versions table
    create_table :agenda_versions do |t|
      t.references :meeting, null: false, foreign_key: true
      t.integer :version_number, null: false, default: 1
      t.integer :agenda_pages
      t.timestamps
    end

    add_index :agenda_versions, [ :meeting_id, :version_number ], unique: true

    # Phase B: Rewire agenda_sections
    add_reference :agenda_sections, :agenda_version, null: true, foreign_key: true

    # Backfill: create one agenda_version per meeting, point sections to it
    execute <<~SQL
      INSERT INTO agenda_versions (meeting_id, version_number, agenda_pages, created_at, updated_at)
      SELECT id, 1, agenda_pages, created_at, updated_at
      FROM meetings
    SQL

    execute <<~SQL
      UPDATE agenda_sections
      SET agenda_version_id = (
        SELECT agenda_versions.id
        FROM agenda_versions
        WHERE agenda_versions.meeting_id = agenda_sections.meeting_id
      )
    SQL

    change_column_null :agenda_sections, :agenda_version_id, false

    remove_index :agenda_sections, name: "index_agenda_sections_on_meeting_id_and_number"
    remove_index :agenda_sections, name: "index_agenda_sections_on_meeting_id"
    remove_foreign_key :agenda_sections, :meetings
    remove_column :agenda_sections, :meeting_id

    add_index :agenda_sections, [ :agenda_version_id, :number ], unique: true

    # Phase C: Drop agenda_pages from meetings
    remove_column :meetings, :agenda_pages
  end

  def down
    # Phase C reverse: restore agenda_pages to meetings
    add_column :meetings, :agenda_pages, :integer

    # Phase B reverse: restore meeting_id to agenda_sections
    add_reference :agenda_sections, :meeting, null: true, foreign_key: true

    execute <<~SQL
      UPDATE agenda_sections
      SET meeting_id = (
        SELECT agenda_versions.meeting_id
        FROM agenda_versions
        WHERE agenda_versions.id = agenda_sections.agenda_version_id
      )
    SQL

    # Restore agenda_pages from version 1
    execute <<~SQL
      UPDATE meetings
      SET agenda_pages = (
        SELECT agenda_versions.agenda_pages
        FROM agenda_versions
        WHERE agenda_versions.meeting_id = meetings.id
          AND agenda_versions.version_number = 1
      )
    SQL

    change_column_null :agenda_sections, :meeting_id, false

    remove_index :agenda_sections, [ :agenda_version_id, :number ]
    remove_foreign_key :agenda_sections, :agenda_versions
    remove_column :agenda_sections, :agenda_version_id

    add_index :agenda_sections, [ :meeting_id, :number ], unique: true
    add_index :agenda_sections, :meeting_id

    # Phase A reverse: drop agenda_versions table
    drop_table :agenda_versions
  end
end
