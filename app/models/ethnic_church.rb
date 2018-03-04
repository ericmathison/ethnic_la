class EthnicChurch < ApplicationRecord
  has_one :address
  has_one :note
  belongs_to :language
  belongs_to :country
  belongs_to :religious_background
end
