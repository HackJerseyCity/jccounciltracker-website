class RemoveUniquenessFromAgendaSectionsNumber < ActiveRecord::Migration[8.1]
  def change
    remove_index :agenda_sections, [ :agenda_version_id, :number ], unique: true
    add_index :agenda_sections, [ :agenda_version_id, :number ]
  end
end
