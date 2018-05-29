class RemoveTimestampsFromEthnicChurchesLanguagesJoinTable < ActiveRecord::Migration[5.2]
  def change
    remove_timestamps :ethnic_churches_languages
  end
end
