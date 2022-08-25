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

ActiveRecord::Schema[7.0].define(version: 2018_08_25_085348) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "city"
    t.string "zip"
    t.bigint "ethnic_church_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.float "latitude"
    t.float "longitude"
    t.index ["ethnic_church_id"], name: "index_addresses_on_ethnic_church_id"
  end

  create_table "admins", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["email"], name: "index_admins_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admins_on_reset_password_token", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_countries_on_name", unique: true
  end

  create_table "ethnic_churches", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "website"
    t.string "pastors_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "email"
    t.bigint "country_id"
    t.bigint "religious_background_id"
    t.boolean "unconfirmed"
    t.index ["country_id"], name: "index_ethnic_churches_on_country_id"
    t.index ["religious_background_id"], name: "index_ethnic_churches_on_religious_background_id"
  end

  create_table "languages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "endonym"
    t.index ["name"], name: "index_languages_on_name", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.string "content"
    t.bigint "ethnic_church_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["ethnic_church_id"], name: "index_notes_on_ethnic_church_id"
  end

  create_table "religious_backgrounds", force: :cascade do |t|
    t.string "persuasion"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["persuasion"], name: "index_religious_backgrounds_on_persuasion", unique: true
  end

  create_table "services", id: false, force: :cascade do |t|
    t.bigint "ethnic_church_id", null: false
    t.bigint "language_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  add_foreign_key "addresses", "ethnic_churches"
  add_foreign_key "ethnic_churches", "countries"
  add_foreign_key "ethnic_churches", "religious_backgrounds"
  add_foreign_key "notes", "ethnic_churches"
end
