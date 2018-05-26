# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_05_26_005155) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.bigint "ethnic_church_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["ethnic_church_id"], name: "index_addresses_on_ethnic_church_id"
  end

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_countries_on_name", unique: true
  end

  create_table "ethnic_churches", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "website"
    t.string "pastors_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.bigint "country_id"
    t.bigint "religious_background_id"
    t.index ["country_id"], name: "index_ethnic_churches_on_country_id"
    t.index ["religious_background_id"], name: "index_ethnic_churches_on_religious_background_id"
  end

  create_table "ethnic_churches_languages", id: false, force: :cascade do |t|
    t.bigint "ethnic_church_id", null: false
    t.bigint "language_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.string "content"
    t.bigint "ethnic_church_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["ethnic_church_id"], name: "index_notes_on_ethnic_church_id"
  end

  create_table "religious_backgrounds", force: :cascade do |t|
    t.string "persuasion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["persuasion"], name: "index_religious_backgrounds_on_persuasion", unique: true
  end

  add_foreign_key "addresses", "ethnic_churches"
  add_foreign_key "ethnic_churches", "countries"
  add_foreign_key "ethnic_churches", "religious_backgrounds"
  add_foreign_key "notes", "ethnic_churches"
end
