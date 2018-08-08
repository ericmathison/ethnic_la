class Language < ApplicationRecord
  has_many :services
  has_many :ethnic_churches, through: :services

  validates :name, uniqueness: true
end
