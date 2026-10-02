# A small dot map of where a language's English learners go to school, drawn
# as SVG circles on the language map's browse page. Schools are binned into a
# grid so languages spoken at thousands of schools stay light.
class LanguageFootprint
  # The Los Angeles area frame (covers 99% of mapped schools)
  WEST = -119.35
  EAST = -116.0
  NORTH = 34.75
  SOUTH = 33.35
  WIDTH = 200
  HEIGHT = (WIDTH * (NORTH - SOUTH) / ((EAST - WEST) * Math.cos(34 * Math::PI / 180))).round
  CELL = 2

  Dot = Struct.new(:x, :y, :r)

  attr_reader :language, :endonym, :lang, :year, :english_learners, :dots

  def self.endonyms
    @endonyms ||= YAML.load_file(Rails.root.join('config/school_language_endonyms.yml'))
  end

  # One footprint per language, from its most recent year with English learners
  def self.all
    latest = SchoolLanguageCount.group(:school_language_id).maximum(:year)
    rows = SchoolLanguageCount.joins(:school)
                              .where(latest.map { |id, year| "(school_language_id = #{id.to_i} AND year = #{year.to_i})" }.join(' OR ').presence || 'FALSE')
                              .pluck(:school_language_id, :english_learners, 'schools.latitude', 'schools.longitude')
                              .group_by(&:first)

    SchoolLanguage.order(:name).filter_map do |language|
      next unless latest[language.id]

      new(language, latest[language.id], rows.fetch(language.id, []).map { _1.drop(1) })
    end
  end

  # Gray dots for every mapped school, drawn under each footprint
  def self.base_dots
    weighted = School.where.not(latitude: nil).pluck(:latitude, :longitude).map { |lat, lng| [1, lat, lng] }
    dots_for(weighted).map { |dot| Dot.new(dot.x, dot.y, 0.7) }
  end

  # [[count, latitude, longitude]] -> dots sized by each cell's share of the busiest cell
  def self.dots_for(weighted)
    cells = Hash.new(0)
    weighted.each do |count, lat, lng|
      next if lat.nil? || lng.nil? || lng < WEST || lng > EAST || lat < SOUTH || lat > NORTH

      x = ((lng - WEST) / (EAST - WEST) * WIDTH / CELL).floor
      y = ((NORTH - lat) / (NORTH - SOUTH) * HEIGHT / CELL).floor
      cells[[x, y]] += count
    end
    max = cells.values.max.to_f
    cells.map do |(x, y), count|
      Dot.new((x + 0.5) * CELL, (y + 0.5) * CELL, (0.9 + 3.1 * Math.sqrt(count / max)).round(1))
    end
  end

  def initialize(language, year, counts)
    @language = language
    @year = year
    @english_learners = counts.sum(&:first)
    @dots = self.class.dots_for(counts)
    details = self.class.endonyms.fetch(language.name, {})
    @endonym = details['endonym']
    @lang = details['lang']
  end
end
