class AddUniqueConstraintToLanguageCountryAndReligiousBackground < ActiveRecord::Migration[5.1]
  def change
		add_index :languages, :name, unique: true
		add_index :countries, :name, unique: true
		add_index :religious_backgrounds, :persuasion, unique: true
  end
end
