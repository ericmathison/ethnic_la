class AddEndonymousNameToLanguage < ActiveRecord::Migration[5.2]
  def change
    add_column :languages, :endonymous_name, :string
  end
end
