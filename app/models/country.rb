class Country < ApplicationRecord
  has_many :ethnic_churches

  validates :name, uniqueness: true
end
