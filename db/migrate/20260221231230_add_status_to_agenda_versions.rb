class AddStatusToAgendaVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :agenda_versions, :status, :string, null: false, default: "draft"
    add_index :agenda_versions, :status
  end
end
