class RemoveMoreFieldsFromEthnicChurches < ActiveRecord::Migration[5.1]
  def change
    remove_column :ethnic_churches, :language, :string
    remove_column :ethnic_churches, :country, :string
    remove_column :ethnic_churches, :notes, :string
  end
end
