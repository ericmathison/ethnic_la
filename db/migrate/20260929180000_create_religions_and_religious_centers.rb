class CreateReligionsAndReligiousCenters < ActiveRecord::Migration[8.1]
  def change
    create_table :religions do |t|
      t.string :name, null: false
      t.string :slug, null: false
      # Admin-only religions (e.g. "Other") hold records that still need research
      t.boolean :admin_only, null: false, default: false
      t.timestamps
    end
    add_index :religions, :name, unique: true
    add_index :religions, :slug, unique: true

    create_table :religious_centers do |t|
      # Public details
      t.string :name, null: false
      t.string :street
      t.string :city
      t.string :zip
      t.string :phone
      t.string :website
      t.string :community
      t.float :latitude
      t.float :longitude

      # verified centers are public; unverified and not_found are admin-only
      t.string :status, null: false, default: 'verified'

      # Admin-only details
      t.string :leader
      t.string :email
      t.text :notes
      t.boolean :name_uncertain, null: false, default: false
      t.string :geocode_match
      # Row in the source spreadsheet, so re-imports update instead of duplicating
      t.integer :source_row

      t.timestamps
    end
    add_index :religious_centers, :status
    add_index :religious_centers, :source_row, unique: true

    create_table :religion_memberships do |t|
      t.references :religion, null: false, foreign_key: true
      t.references :religious_center, null: false, foreign_key: true
      t.timestamps
    end
    add_index :religion_memberships, %i[religion_id religious_center_id], unique: true, name: 'index_religion_memberships_uniqueness'
  end
end
