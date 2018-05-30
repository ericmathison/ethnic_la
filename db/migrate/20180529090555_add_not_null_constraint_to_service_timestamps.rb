class AddNotNullConstraintToServiceTimestamps < ActiveRecord::Migration[5.2]
  def change
    change_column_null :services, :created_at, false
    change_column_null :services, :updated_at, false
  end
end
