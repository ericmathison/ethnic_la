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

ActiveRecord::Schema[8.1].define(version: 2026_10_02_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "census_tracts", force: :cascade do |t|
    t.string "geoid", null: false
    t.string "county", null: false
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["geoid"], name: "index_census_tracts_on_geoid", unique: true
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

  create_table "ethnicities", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "census_code", null: false
    t.string "category", null: false
    t.integer "people", null: false
    t.jsonb "people_by_county", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["census_code"], name: "index_ethnicities_on_census_code", unique: true
    t.index ["slug"], name: "index_ethnicities_on_slug", unique: true
  end

  create_table "ethnicity_counts", force: :cascade do |t|
    t.bigint "ethnicity_id", null: false
    t.bigint "census_tract_id", null: false
    t.integer "people", null: false
    t.index ["census_tract_id"], name: "index_ethnicity_counts_on_census_tract_id"
    t.index ["ethnicity_id", "census_tract_id"], name: "index_ethnicity_counts_on_ethnicity_id_and_census_tract_id", unique: true
    t.index ["ethnicity_id"], name: "index_ethnicity_counts_on_ethnicity_id"
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

  create_table "religion_memberships", force: :cascade do |t|
    t.bigint "religion_id", null: false
    t.bigint "religious_center_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["religion_id", "religious_center_id"], name: "index_religion_memberships_uniqueness", unique: true
    t.index ["religion_id"], name: "index_religion_memberships_on_religion_id"
    t.index ["religious_center_id"], name: "index_religion_memberships_on_religious_center_id"
  end

  create_table "religions", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.boolean "admin_only", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_religions_on_name", unique: true
    t.index ["slug"], name: "index_religions_on_slug", unique: true
  end

  create_table "religious_backgrounds", force: :cascade do |t|
    t.string "persuasion"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["persuasion"], name: "index_religious_backgrounds_on_persuasion", unique: true
  end

  create_table "religious_centers", force: :cascade do |t|
    t.string "name", null: false
    t.string "street"
    t.string "city"
    t.string "zip"
    t.string "phone"
    t.string "website"
    t.string "community"
    t.float "latitude"
    t.float "longitude"
    t.string "status", default: "verified", null: false
    t.string "leader"
    t.string "email"
    t.text "notes"
    t.boolean "name_uncertain", default: false, null: false
    t.string "geocode_match"
    t.integer "source_row"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_row"], name: "index_religious_centers_on_source_row", unique: true
    t.index ["status"], name: "index_religious_centers_on_status"
  end

  create_table "school_language_counts", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "school_language_id", null: false
    t.integer "year", null: false
    t.integer "english_learners", null: false
    t.index ["school_id"], name: "index_school_language_counts_on_school_id"
    t.index ["school_language_id", "year", "school_id"], name: "index_school_language_counts_uniqueness", unique: true
    t.index ["school_language_id"], name: "index_school_language_counts_on_school_language_id"
  end

  create_table "school_languages", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_school_languages_on_name", unique: true
    t.index ["slug"], name: "index_school_languages_on_slug", unique: true
  end

  create_table "schools", force: :cascade do |t|
    t.string "cds_code", null: false
    t.string "name", null: false
    t.string "district"
    t.string "county"
    t.string "city"
    t.float "latitude"
    t.float "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cds_code"], name: "index_schools_on_cds_code", unique: true
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
  add_foreign_key "ethnicity_counts", "census_tracts"
  add_foreign_key "ethnicity_counts", "ethnicities"
  add_foreign_key "notes", "ethnic_churches"
  add_foreign_key "religion_memberships", "religions"
  add_foreign_key "religion_memberships", "religious_centers"
  add_foreign_key "school_language_counts", "school_languages"
  add_foreign_key "school_language_counts", "schools"
end
