class AddUnconfirmedToEthnicChurch < ActiveRecord::Migration[5.2]
  def change
    add_column :ethnic_churches, :unconfirmed, :boolean
  end
end
