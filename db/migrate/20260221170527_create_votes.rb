class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :agenda_item, null: false, foreign_key: true
      t.references :council_member, null: false, foreign_key: true
      t.string :position, null: false

      t.timestamps
    end

    add_index :votes, [ :agenda_item_id, :council_member_id ], unique: true
    add_index :votes, [ :council_member_id, :position ]
  end
end
