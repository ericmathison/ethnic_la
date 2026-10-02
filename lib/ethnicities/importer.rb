require 'csv'
require 'json'

module Ethnicities
  # Loads detailed race and ethnic groups for the Los Angeles area from the
  # 2020 Census Detailed DHC-A (https://www.census.gov/data/tables/2023/dec/2020-census-detailed-dhc-a.html).
  # Expects in dir:
  #
  # - 2020-ddhc-a.zip: the national summary file
  #   (https://www2.census.gov/programs-surveys/decennial/2020/data/detailed-dhc-a/);
  #   only table T01001 (total population) is read
  # - popgroups.json: the group codes and names
  #   (https://api.census.gov/data/2020/dec/ddhca/variables/POPGROUP.json)
  # - 2020_gaz_tracts_06.txt: California tract internal points
  #   (https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2020_Gazetteer/)
  #
  # Replaces all existing ethnicity data, so it's safe to re-run.
  class Importer
    COUNTIES = { '037' => 'Los Angeles', '059' => 'Orange', '111' => 'Ventura', '065' => 'Riverside',
                 '071' => 'San Bernardino' }.freeze
    COUNTY_GEOIDS = COUNTIES.keys.map { "0500000US06#{_1}" }.freeze
    TRACT_PREFIXES = COUNTIES.keys.map { "1400000US06#{_1}" }.freeze

    # Umbrella groups that sum other groups, and write-ins too general to be a community
    UMBRELLAS = %w[
      1113 1182 1211 1293 1337 2562 2833 3821 3829 3838 3850 3920 3936 3952 4016 4024 4035
    ].freeze
    NAMES = {
      'Chinese, except Taiwanese' => 'Chinese', 'Nigerian (Nigeria)' => 'Nigerian', 'Argentinean' => 'Argentine',
      'Blackfeet Tribe of the Blackfeet Indian Reservation of Montana' => 'Blackfeet'
    }.freeze
    # Groups the Census lists with Europe that the site groups by region of origin
    CATEGORY_OVERRIDES = { '1117' => 'Middle East & North Africa', '1177' => 'Middle East & North Africa',
                           '3989' => 'Latin America', '3991' => 'Latin America', '3996' => 'Africa',
                           '1213' => 'Other', '1218' => 'Other' }.freeze

    Result = Struct.new(:ethnicities, :tracts, :counts, keyword_init: true)

    def self.import(dir)
      new(dir).import
    end

    # Region of origin for a Census group code, or nil for codes not shown
    def self.category(code)
      return CATEGORY_OVERRIDES[code] if CATEGORY_OVERRIDES.key?(code)
      return unless code.match?(/\A\d{4}\z/)

      case code.to_i
      when 1113..1181 then 'Europe'
      when 1182..1210 then 'Middle East & North Africa'
      when 1211..1222, 1292 then 'United States & Canada'
      when 1293..1336 then 'Africa'
      when 1337..1355 then 'Caribbean'
      when 2562..3799 then 'Indigenous Americas'
      when 3800..3899 then 'Asia'
      when 3900..3979 then 'Pacific Islands'
      when 4015..4053 then 'Latin America'
      end
    end

    # "Armenian" from "Armenian alone or in any combination", or nil for
    # versions not shown ("alone"), umbrella groups, and unspecified groups
    def self.name(code, label)
      return if UMBRELLAS.include?(code) || category(code).nil?
      return if label.match?(/not specified|\AOther |\(all tribes\)/)

      if code.to_i < 4000 || code.to_i > 4053
        return unless label.end_with?(' alone or in any combination')

        label = label.delete_suffix(' alone or in any combination')
      end
      label = label.strip
      NAMES.fetch(label, label)
    end

    def initialize(dir)
      @dir = dir.to_s
    end

    def import
      groups = JSON.parse(File.read(File.join(@dir, 'popgroups.json'))).dig('values', 'item')
                   .to_h { |code, label| [code, self.class.name(code, label)] }.compact
      tracts = read_tracts
      county_people, tract_people = read_counts(groups)
      # Only groups that can be mapped
      codes = tract_people.keys.map(&:first).uniq

      Ethnicity.transaction do
        EthnicityCount.delete_all
        Ethnicity.delete_all
        CensusTract.delete_all

        now = Time.current
        tract_ids = insert_all(CensusTract, tracts.map { |geoid, attributes| attributes.merge(geoid: geoid, created_at: now, updated_at: now) }, 'geoid')
        ethnicity_ids = insert_all(Ethnicity, codes.map do |code|
          by_county = county_people.select { |(c, _), _| c == code }.to_h { |(_, county), people| [county, people] }
          { census_code: code, name: groups.fetch(code), slug: slug(groups.fetch(code), code), category: self.class.category(code),
            people: by_county.values.sum, people_by_county: by_county, created_at: now, updated_at: now }
        end, 'census_code')
        rows = tract_people.filter_map do |(code, geoid), people|
          next unless tract_ids[geoid]

          { ethnicity_id: ethnicity_ids.fetch(code), census_tract_id: tract_ids[geoid], people: people }
        end
        rows.each_slice(10_000) { EthnicityCount.insert_all!(_1) }
      end

      Result.new(ethnicities: Ethnicity.count, tracts: CensusTract.count, counts: EthnicityCount.count)
    end

    private

    # Returns { geoid => { county:, latitude:, longitude: } }
    def read_tracts
      File.foreach(File.join(@dir, '2020_gaz_tracts_06.txt')).drop(1).each_with_object({}) do |line, tracts|
        _, geoid, *, lat, lng = line.split("\t").map(&:strip)
        county = COUNTIES[geoid[2, 3]]
        tracts[geoid] = { county: county, latitude: lat.to_f, longitude: lng.to_f } if county
      end
    end

    # Returns { [code, county] => people } and { [code, tract geoid] => people }
    def read_counts(groups)
      county_people = {}
      tract_people = {}
      IO.popen(['unzip', '-p', File.join(@dir, '2020-ddhc-a.zip'), 'ddhca_t01001.csv']) do |io|
        io.each_line do |line|
          region_type, _, geoid, _, code, count = line.split(',', 7)
          next unless %w[COUNTY TRACT].include?(region_type) && groups.key?(code)

          people = count.to_i
          # Negative counts mark groups below the Census reporting threshold
          next unless people.positive?

          if region_type == 'COUNTY'
            county_people[[code, COUNTIES[geoid[-3, 3]]]] = people if COUNTY_GEOIDS.include?(geoid)
          elsif TRACT_PREFIXES.include?(geoid[0, 14])
            tract_people[[code, geoid.delete_prefix('1400000US')]] = people
          end
        end
      end
      raise "Couldn't read ddhca_t01001.csv from 2020-ddhc-a.zip in #{@dir}" if county_people.empty?

      [county_people, tract_people]
    end

    # Some names repeat across Census categories (e.g. a tribe listed twice)
    def slug(name, code)
      @slugs ||= Hash.new(0)
      base = name.parameterize
      @slugs[base] += 1
      @slugs[base] == 1 ? base : "#{base}-#{code}"
    end

    # Inserts rows and returns { key => id }
    def insert_all(model, rows, key)
      rows.each_slice(5_000).each_with_object({}) do |slice, ids|
        model.insert_all!(slice, returning: [:id, key]).each { |row| ids[row[key]] = row['id'] }
      end
    end
  end
end
