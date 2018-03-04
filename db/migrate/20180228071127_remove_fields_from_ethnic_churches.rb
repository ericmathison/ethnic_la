class RemoveFieldsFromEthnicChurches < ActiveRecord::Migration[5.1]
  def change
    remove_column :ethnic_churches, :street, :string
    remove_column :ethnic_churches, :city, :string
    remove_column :ethnic_churches, :state, :string
    remove_column :ethnic_churches, :zip, :string
    remove_column :ethnic_churches, :religious_background, :string
  end
end
