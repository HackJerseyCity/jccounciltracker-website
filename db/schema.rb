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

ActiveRecord::Schema[8.1].define(version: 2026_03_22_180435) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "metadata"
    t.integer "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["action"], name: "index_admin_audit_logs_on_action"
    t.index ["created_at"], name: "index_admin_audit_logs_on_created_at"
    t.index ["target_type", "target_id"], name: "index_admin_audit_logs_on_target_type_and_target_id"
    t.index ["user_id"], name: "index_admin_audit_logs_on_user_id"
  end

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
    t.index ["agenda_version_id", "number"], name: "index_agenda_sections_on_agenda_version_id_and_number"
    t.index ["agenda_version_id"], name: "index_agenda_sections_on_agenda_version_id"
  end

  create_table "agenda_versions", force: :cascade do |t|
    t.integer "agenda_pages"
    t.datetime "created_at", null: false
    t.integer "meeting_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", default: 1, null: false
    t.index ["meeting_id", "version_number"], name: "index_agenda_versions_on_meeting_id_and_version_number", unique: true
    t.index ["meeting_id"], name: "index_agenda_versions_on_meeting_id"
    t.index ["status"], name: "index_agenda_versions_on_status"
  end

  create_table "blog_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["slug"], name: "index_blog_posts_on_slug", unique: true
    t.index ["user_id"], name: "index_blog_posts_on_user_id"
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

  create_table "email_campaigns", force: :cascade do |t|
    t.string "campaign_type", default: "council_updates", null: false
    t.datetime "created_at", null: false
    t.datetime "sent_at"
    t.integer "sent_count", default: 0
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_email_campaigns_on_status"
    t.index ["user_id"], name: "index_email_campaigns_on_user_id"
  end

  create_table "email_deliveries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "email_campaign_id", null: false
    t.datetime "sent_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["email_campaign_id", "user_id"], name: "index_email_deliveries_on_email_campaign_id_and_user_id", unique: true
    t.index ["email_campaign_id"], name: "index_email_deliveries_on_email_campaign_id"
    t.index ["status"], name: "index_email_deliveries_on_status"
    t.index ["user_id"], name: "index_email_deliveries_on_user_id"
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

  create_table "stars", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "starrable_id", null: false
    t.string "starrable_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["starrable_type", "starrable_id"], name: "index_stars_on_starrable"
    t.index ["user_id", "starrable_type", "starrable_id"], name: "index_stars_on_user_id_and_starrable_type_and_starrable_id", unique: true
    t.index ["user_id"], name: "index_stars_on_user_id"
  end

  create_table "tag_rules", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "match_type", default: "keyword", null: false
    t.string "pattern", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_tag_rules_on_tag_id"
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
    t.boolean "email_blog", default: true, null: false
    t.boolean "email_council_updates", default: true, null: false
    t.boolean "email_marketing", default: true, null: false
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admin_audit_logs", "users"
  add_foreign_key "agenda_item_tags", "agenda_items"
  add_foreign_key "agenda_item_tags", "tags"
  add_foreign_key "agenda_items", "agenda_sections"
  add_foreign_key "agenda_sections", "agenda_versions"
  add_foreign_key "agenda_versions", "meetings"
  add_foreign_key "blog_posts", "users"
  add_foreign_key "email_campaigns", "users"
  add_foreign_key "email_deliveries", "email_campaigns"
  add_foreign_key "email_deliveries", "users"
  add_foreign_key "invitations", "users", column: "accepted_by_id"
  add_foreign_key "invitations", "users", column: "invited_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "stars", "users"
  add_foreign_key "tag_rules", "tags"
  add_foreign_key "votes", "agenda_items"
  add_foreign_key "votes", "council_members"
end
