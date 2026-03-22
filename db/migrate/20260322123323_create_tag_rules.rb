class CreateTagRules < ActiveRecord::Migration[8.1]
  def change
    create_table :tag_rules do |t|
      t.references :tag, null: false, foreign_key: true
      t.string :pattern, null: false
      t.string :match_type, null: false, default: "keyword"

      t.timestamps
    end
  end
end
