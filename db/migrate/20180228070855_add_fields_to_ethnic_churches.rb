class AddFieldsToEthnicChurches < ActiveRecord::Migration[5.1]
  def change
    add_column :ethnic_churches, :email, :string
    add_reference :ethnic_churches, :language, foreign_key: true
    add_reference :ethnic_churches, :country, foreign_key: true
    add_reference :ethnic_churches, :religious_background, foreign_key: true
  end
end
