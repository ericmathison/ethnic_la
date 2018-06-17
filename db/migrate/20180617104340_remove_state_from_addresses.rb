class RemoveStateFromAddresses < ActiveRecord::Migration[5.2]
  def up
    remove_column :addresses, :state
  end

  def down
    add_column :addresses, :state, :string
  end
end
