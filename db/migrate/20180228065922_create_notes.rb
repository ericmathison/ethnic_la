class CreateNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :notes do |t|
      t.string :content
      t.references :ethnic_church, foreign_key: true
    end
  end
end
