class Ethnicity < ApplicationRecord
  has_many :ethnicity_counts, dependent: :delete_all

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :census_code, presence: true, uniqueness: true

  # Category filters on the ethnicity map, in display order
  CATEGORIES = ['Latin America', 'Indigenous Americas', 'Asia', 'Pacific Islands', 'Middle East & North Africa',
                'Europe', 'Africa', 'Caribbean', 'United States & Canada', 'Other'].freeze

  def to_param
    slug
  end

  # One point per tract: { lng:, lat:, name:, district:, counts: [people] }, shaped
  # like the language map's points so the same map script can draw both
  def map_points
    ethnicity_counts.joins(:census_tract)
                    .pluck('census_tracts.geoid', 'census_tracts.county', 'census_tracts.latitude', 'census_tracts.longitude', :people)
                    .map do |geoid, county, lat, lng, people|
      { lng: lng.round(5), lat: lat.round(5), name: "Census tract #{CensusTract.tract_name(geoid)}", district: "#{county} County", counts: [people] }
    end
  end
end
