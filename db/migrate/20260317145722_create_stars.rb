class CreateStars < ActiveRecord::Migration[8.1]
  def change
    create_table :stars do |t|
      t.references :user, null: false, foreign_key: true
      t.references :starrable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :stars, [ :user_id, :starrable_type, :starrable_id ], unique: true
  end
end
