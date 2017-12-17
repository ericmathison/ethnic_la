class CreateEthnicChurches < ActiveRecord::Migration[5.1]
  def change
    create_table :ethnic_churches do |t|
      t.string :name
      t.string :street
      t.string :city
      t.string :state
      t.string :zip
      t.string :phone
      t.string :website
      t.string :language
      t.string :country
      t.string :religious_background
      t.string :pastors_name
      t.text :notes

      t.timestamps
    end
  end
end
