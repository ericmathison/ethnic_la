# Where a group's members live (by census tract), for the ethnicity map's cards
class EthnicityFootprint < Footprint
  attr_reader :ethnicity, :dots

  def self.all
    rows = EthnicityCount.joins(:census_tract)
                         .pluck(:ethnicity_id, :people, 'census_tracts.latitude', 'census_tracts.longitude')
                         .group_by(&:first)
    Ethnicity.order(:name).map { new(_1, rows.fetch(_1.id, []).map { |row| row.drop(1) }) }
  end

  def initialize(ethnicity, counts)
    @ethnicity = ethnicity
    @dots = self.class.dots_for(counts)
  end
end
