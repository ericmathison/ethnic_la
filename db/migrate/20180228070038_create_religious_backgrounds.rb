class CreateReligiousBackgrounds < ActiveRecord::Migration[5.1]
  def change
    create_table :religious_backgrounds do |t|
      t.string :persuasion
    end
  end
end
