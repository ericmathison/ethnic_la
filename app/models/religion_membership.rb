class ReligionMembership < ApplicationRecord
  belongs_to :religion
  belongs_to :religious_center
end
