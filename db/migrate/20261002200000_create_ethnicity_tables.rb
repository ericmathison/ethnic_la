class CreateEthnicityTables < ActiveRecord::Migration[8.1]
  def change
    # 2020 Census tracts, located by the Census Bureau's internal point
    create_table :census_tracts do |t|
      t.string :geoid, null: false
      t.string :county, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.timestamps
    end
    add_index :census_tracts, :geoid, unique: true

    # Detailed race and ethnic groups from the 2020 Census Detailed DHC-A
    create_table :ethnicities do |t|
      t.string :name, null: false
      t.string :slug, null: false
      # The Census POPGROUP code
      t.string :census_code, null: false
      # Region of origin, used to filter the ethnicity map's cards
      t.string :category, null: false
      # People in the five counties, from county totals (tract counts leave out small groups)
      t.integer :people, null: false
      t.jsonb :people_by_county, null: false, default: {}
      t.timestamps
    end
    add_index :ethnicities, :slug, unique: true
    add_index :ethnicities, :census_code, unique: true

    create_table :ethnicity_counts do |t|
      t.references :ethnicity, null: false, foreign_key: true
      t.references :census_tract, null: false, foreign_key: true
      t.integer :people, null: false
    end
    add_index :ethnicity_counts, %i[ethnicity_id census_tract_id], unique: true
  end
end
