class CreateAdminAuditLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false
      t.string :target_type
      t.integer :target_id
      t.text :metadata

      t.timestamps
    end

    add_index :admin_audit_logs, :action
    add_index :admin_audit_logs, [ :target_type, :target_id ]
    add_index :admin_audit_logs, :created_at
  end
end
