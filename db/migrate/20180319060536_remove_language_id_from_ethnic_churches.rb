class RemoveLanguageIdFromEthnicChurches < ActiveRecord::Migration[5.1]
  def up
    remove_column :ethnic_churches, :language_id, :bigint
  end

  def down
    add_reference :ethnic_churches, :language, foreign_key: true
  end
end
