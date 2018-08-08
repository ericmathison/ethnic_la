class ChangeEndonymousNameToEndonym < ActiveRecord::Migration[5.2]
  def change
    rename_column :languages, :endonymous_name, :endonym
  end
end
