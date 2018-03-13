class Language < ApplicationRecord
  has_many :ethnic_churches

  validates :name, uniqueness: true

  def self.list
    pluck(:id, :name)
      .map { |lang| {id: lang[0], name: lang[1]} }
      .sort_by { |lang| lang[:name].to_s }
  end
end
