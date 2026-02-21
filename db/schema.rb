# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_21_213459) do
  create_table "agenda_item_tags", force: :cascade do |t|
    t.integer "agenda_item_id", null: false
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["agenda_item_id", "tag_id"], name: "index_agenda_item_tags_on_agenda_item_id_and_tag_id", unique: true
    t.index ["agenda_item_id"], name: "index_agenda_item_tags_on_agenda_item_id"
    t.index ["tag_id"], name: "index_agenda_item_tags_on_tag_id"
  end

  create_table "agenda_items", force: :cascade do |t|
    t.integer "agenda_section_id", null: false
    t.datetime "created_at", null: false
    t.string "file_number"
    t.string "item_number", null: false
    t.string "item_type", null: false
    t.integer "page_end"
    t.integer "page_start"
    t.integer "position", default: 0, null: false
    t.string "result"
    t.text "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "vote_tally"
    t.index ["agenda_section_id", "item_number"], name: "index_agenda_items_on_agenda_section_id_and_item_number", unique: true
    t.index ["agenda_section_id"], name: "index_agenda_items_on_agenda_section_id"
  end

  create_table "agenda_sections", force: :cascade do |t|
    t.integer "agenda_version_id", null: false
    t.datetime "created_at", null: false
    t.integer "number", null: false
    t.string "section_type", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["agenda_version_id", "number"], name: "index_agenda_sections_on_agenda_version_id_and_number", unique: true
    t.index ["agenda_version_id"], name: "index_agenda_sections_on_agenda_version_id"
  end

  create_table "agenda_versions", force: :cascade do |t|
    t.integer "agenda_pages"
    t.datetime "created_at", null: false
    t.integer "meeting_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", default: 1, null: false
    t.index ["meeting_id", "version_number"], name: "index_agenda_versions_on_meeting_id_and_version_number", unique: true
    t.index ["meeting_id"], name: "index_agenda_versions_on_meeting_id"
  end

  create_table "council_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "seat", null: false
    t.date "term_end"
    t.date "term_start", null: false
    t.datetime "updated_at", null: false
    t.index ["last_name"], name: "index_council_members_on_last_name"
  end

  create_table "invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.integer "accepted_by_id"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_id", null: false
    t.integer "role", default: 1, null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["accepted_by_id"], name: "index_invitations_on_accepted_by_id"
    t.index ["invited_by_id"], name: "index_invitations_on_invited_by_id"
    t.index ["token"], name: "index_invitations_on_token", unique: true
  end

  create_table "meetings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "meeting_type", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "meeting_type"], name: "index_meetings_on_date_and_meeting_type", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "LOWER(name)", name: "index_tags_on_lower_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "votes", force: :cascade do |t|
    t.integer "agenda_item_id", null: false
    t.integer "council_member_id", null: false
    t.datetime "created_at", null: false
    t.string "position", null: false
    t.datetime "updated_at", null: false
    t.index ["agenda_item_id", "council_member_id"], name: "index_votes_on_agenda_item_id_and_council_member_id", unique: true
    t.index ["agenda_item_id"], name: "index_votes_on_agenda_item_id"
    t.index ["council_member_id", "position"], name: "index_votes_on_council_member_id_and_position"
    t.index ["council_member_id"], name: "index_votes_on_council_member_id"
  end

  add_foreign_key "agenda_item_tags", "agenda_items"
  add_foreign_key "agenda_item_tags", "tags"
  add_foreign_key "agenda_items", "agenda_sections"
  add_foreign_key "agenda_sections", "agenda_versions"
  add_foreign_key "agenda_versions", "meetings"
  add_foreign_key "invitations", "users", column: "accepted_by_id"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "votes", "agenda_items"
  add_foreign_key "votes", "council_members"
end
