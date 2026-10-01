class CreateSchoolLanguageTables < ActiveRecord::Migration[8.1]
  def change
    # California public schools, from the CDE school directory
    create_table :schools do |t|
      t.string :cds_code, null: false
      t.string :name, null: false
      t.string :district
      t.string :county
      t.string :city
      t.float :latitude
      t.float :longitude
      t.timestamps
    end
    add_index :schools, :cds_code, unique: true

    # Home languages of English learners. Separate from the languages of ethnic
    # churches because CDE's language list doesn't line up with ours.
    create_table :school_languages do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :school_languages, :name, unique: true
    add_index :school_languages, :slug, unique: true

    # English learners at a school who speak a language, by school year
    create_table :school_language_counts do |t|
      t.references :school, null: false, foreign_key: true
      t.references :school_language, null: false, foreign_key: true
      # The year the school year starts in (2025 for 2025-26)
      t.integer :year, null: false
      t.integer :english_learners, null: false
    end
    add_index :school_language_counts, %i[school_language_id year school_id], unique: true, name: 'index_school_language_counts_uniqueness'
  end
end
