# A small dot map of where a group is in the Los Angeles area, drawn as SVG
# circles on the cards of the language and ethnicity maps. Places are binned
# into a grid so groups found in thousands of places stay light.
class Footprint
  # The Los Angeles area frame (covers 99% of mapped schools)
  WEST = -119.35
  EAST = -116.0
  NORTH = 34.75
  SOUTH = 33.35
  WIDTH = 200
  HEIGHT = (WIDTH * (NORTH - SOUTH) / ((EAST - WEST) * Math.cos(34 * Math::PI / 180))).round
  CELL = 3

  Dot = Struct.new(:x, :y, :r)

  # County outlines ({ "name", "path" }) drawn under each footprint, from
  # lib/scripts/build_la_area_outline.rb
  def self.outline
    @outline ||= JSON.parse(File.read(Rails.root.join('config/la_area_outline.json')))
  end

  # Cities labeled on the key map that explains the small maps, with labels to
  # the right (start) or left (end) of the dot
  LANDMARKS = {
    'Oxnard' => [34.197, -119.177, 'start'], 'Santa Clarita' => [34.392, -118.543, 'start'],
    'Los Angeles' => [34.052, -118.244, 'end'], 'Long Beach' => [33.770, -118.194, 'end'],
    'Santa Ana' => [33.746, -117.868, 'start'], 'Riverside' => [33.953, -117.396, 'start'],
    'San Bernardino' => [34.108, -117.290, 'start'], 'Palm Springs' => [33.830, -116.545, 'end'],
    'Lancaster' => [34.687, -118.154, 'start']
  }.freeze

  def self.landmarks
    LANDMARKS.map { |name, (lat, lng, anchor)| [name, *project(lat, lng).map { _1.round(1) }, anchor] }
  end

  # [x, y] in the frame's SVG coordinates
  def self.project(lat, lng)
    [(lng - WEST) / (EAST - WEST) * WIDTH, (NORTH - lat) / (NORTH - SOUTH) * HEIGHT]
  end

  # [[count, latitude, longitude]] -> dots sized by each cell's share of the busiest cell
  def self.dots_for(weighted)
    cells = Hash.new(0)
    weighted.each do |count, lat, lng|
      next if lat.nil? || lng.nil? || lng < WEST || lng > EAST || lat < SOUTH || lat > NORTH

      x, y = project(lat, lng)
      cells[[(x / CELL).floor, (y / CELL).floor]] += count
    end
    max = cells.values.max.to_f
    cells.map do |(x, y), count|
      Dot.new((x + 0.5) * CELL, (y + 0.5) * CELL, (0.9 + 3.1 * Math.sqrt(count / max)).round(1))
    end
  end
end
