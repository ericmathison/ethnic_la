class AddLockableToAdmins < ActiveRecord::Migration[8.1]
  def change
    add_column :admins, :failed_attempts, :integer, default: 0, null: false
    add_column :admins, :locked_at, :datetime
  end
end
