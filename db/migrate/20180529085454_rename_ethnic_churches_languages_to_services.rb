class RenameEthnicChurchesLanguagesToServices < ActiveRecord::Migration[5.2]
  def change
    rename_table :ethnic_churches_languages, :services
  end
end
