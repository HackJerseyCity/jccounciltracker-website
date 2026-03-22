class CreateEmailDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :email_deliveries do |t|
      t.references :email_campaign, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.datetime :sent_at

      t.timestamps
    end

    add_index :email_deliveries, [ :email_campaign_id, :user_id ], unique: true
    add_index :email_deliveries, :status
  end
end
