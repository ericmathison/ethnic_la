class Language < ApplicationRecord
  has_many :services
  has_many :ethnic_churches, through: :services

  validates :name, uniqueness: true

  def self.list
    pluck(:id, :name)
      .map { |lang| {id: lang[0], name: lang[1]} }
      .sort_by { |lang| lang[:name].to_s }
  end
end
