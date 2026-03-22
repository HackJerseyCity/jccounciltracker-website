class CreateEmailCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :email_campaigns do |t|
      t.string :title, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :sent_at
      t.integer :sent_count, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :email_campaigns, :status
  end
end
