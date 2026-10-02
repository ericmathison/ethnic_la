class EthnicityCount < ApplicationRecord
  belongs_to :ethnicity
  belongs_to :census_tract
end
