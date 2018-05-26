class AddNotNullConstraintToTimestamps < ActiveRecord::Migration[5.2]
  def change
    %i[addresses countries ethnic_churches_languages languages notes religious_backgrounds].each do |table|
      change_column_null table, :created_at, false
      change_column_null table, :updated_at, false
    end
  end
end
