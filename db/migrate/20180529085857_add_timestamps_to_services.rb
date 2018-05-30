class AddTimestampsToServices < ActiveRecord::Migration[5.2]
  def change
    add_timestamps :services, null: true
  end
end
