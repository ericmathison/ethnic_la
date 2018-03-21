class EthnicChurch < ApplicationRecord
  has_and_belongs_to_many :languages
  has_one :address
  has_one :note
  belongs_to :country
  belongs_to :religious_background
end
