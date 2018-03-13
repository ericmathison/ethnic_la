class ReligiousBackground < ApplicationRecord
  has_many :ethnic_churches

  validates :persuasion, uniqueness: true
end
