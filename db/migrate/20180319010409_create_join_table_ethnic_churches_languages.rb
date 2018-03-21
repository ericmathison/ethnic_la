class CreateJoinTableEthnicChurchesLanguages < ActiveRecord::Migration[5.1]
  def change
    create_join_table :ethnic_churches, :languages do |t|
      # t.index [:ethnic_church_id, :language_id]
      # t.index [:language_id, :ethnic_church_id]
    end
  end
end
