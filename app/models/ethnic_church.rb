class EthnicChurch < ApplicationRecord
  has_one :address
  belongs_to :language
end
