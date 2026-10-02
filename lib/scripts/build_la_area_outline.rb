require 'net/http'
require 'json'

# Builds config/la_area_outline.json, the coastline and county lines drawn
# under the language map's small footprint maps, from the state's county
# boundaries (clipped at the shoreline):
# https://gis.data.ca.gov/datasets/CDT::california-county-boundaries-and-identifiers
#
# $ bin/rails runner lib/scripts/build_la_area_outline.rb

SERVICE = 'https://services3.arcgis.com/uknczv4rpevve42E/arcgis/rest/services/' \
          'California_County_Boundaries_and_Identifiers_Blue_Version_view/FeatureServer/1/query'.freeze

frame = Footprint
uri = URI(SERVICE)
uri.query = URI.encode_www_form(
  where: '1=1', geometry: [frame::WEST, frame::SOUTH, frame::EAST, frame::NORTH].join(','),
  geometryType: 'esriGeometryEnvelope', inSR: 4326, spatialRel: 'esriSpatialRelIntersects',
  outFields: 'CDT_NAME_SHORT', outSR: 4326, maxAllowableOffset: 0.004, geometryPrecision: 4, f: 'geojson'
)
features = JSON.parse(Net::HTTP.get(uri)).fetch('features')

counties = features.map do |feature|
  geometry = feature.fetch('geometry')
  polygons = geometry['type'] == 'Polygon' ? [geometry['coordinates']] : geometry['coordinates']
  path = polygons.flat_map do |rings|
    rings.map do |ring|
      points = ring.map { |lng, lat| frame.project(lat, lng).map { _1.round(1) }.join(',') }
      "M#{points.join('L')}Z"
    end
  end.join
  { name: feature.dig('properties', 'CDT_NAME_SHORT'), path: path }
end

File.write(Rails.root.join('config/la_area_outline.json'), JSON.pretty_generate(counties.sort_by { _1[:name] }))
puts "Wrote #{counties.size} counties: #{counties.map { _1[:name] }.sort.join(', ')}"
