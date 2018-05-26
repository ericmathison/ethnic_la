class AddTimestamps < ActiveRecord::Migration[5.2]
  def change
    # allow empty values until time stamps are added (at which point we will add
    # a not null constraint)
    add_timestamps :addresses, null: true
    add_timestamps :countries, null: true
    add_timestamps :ethnic_churches_languages, null: true
    add_timestamps :languages, null: true
    add_timestamps :notes, null: true
    add_timestamps :religious_backgrounds, null: true
  end
end
