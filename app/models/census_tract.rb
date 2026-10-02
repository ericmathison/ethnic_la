class CensusTract < ApplicationRecord
  has_many :ethnicity_counts, dependent: :delete_all

  validates :geoid, presence: true, uniqueness: true

  # "2071.01" for 06037207101
  def self.tract_name(geoid)
    "#{geoid[5, 4].to_i}#{".#{geoid[9, 2]}" unless geoid[9, 2] == '00'}"
  end
end
