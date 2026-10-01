require 'csv'
require_relative 'language_names'

module SchoolLanguages
  # Loads CDE's "English Learners by Grade & Language" files
  # (https://www.cde.ca.gov/ds/ad/fileselsch.asp) for the Los Angeles area into
  # the database, locating schools with CDE's school directory. Expects in dir:
  #
  # - elschYY.txt: one file per school year, named as CDE names them (elsch25
  #   is 2025-26)
  # - schoolsites*.csv: "California Public Schools" from data.ca.gov
  #   (https://gis.data.ca.gov/search?q=california%20public%20schools), for
  #   school locations. Newer files win.
  # - pubschls.txt (optional): CDE's full school directory
  #   (https://www.cde.ca.gov/ds/si/ds/pubschls.asp), which also locates
  #   schools that have since closed.
  #
  # Replaces all existing school language data, so it's safe to re-run.
  class Importer
    COUNTIES = ['Los Angeles', 'Orange', 'Ventura', 'Riverside', 'San Bernardino'].freeze

    Result = Struct.new(:schools, :unmapped_schools, :languages, :counts, :years, keyword_init: true)

    def self.import(dir)
      new(dir).import
    end

    def initialize(dir)
      @dir = dir.to_s
    end

    def import
      counts, schools = read_english_learners
      locations = read_locations

      SchoolLanguageCount.transaction do
        SchoolLanguageCount.delete_all
        School.delete_all
        SchoolLanguage.delete_all

        school_ids = insert_all(School, schools.map { |cds, school| school.merge(cds_code: cds).merge(locations.fetch(cds, {})) }, :cds_code)
        language_ids = insert_all(SchoolLanguage, counts.keys.map { _1[1] }.uniq.map { { name: _1, slug: _1.parameterize } }, :name)
        rows = counts.map do |(cds, language, year), english_learners|
          { school_id: school_ids.fetch(cds), school_language_id: language_ids.fetch(language), year: year, english_learners: english_learners }
        end
        rows.each_slice(10_000) { SchoolLanguageCount.insert_all!(_1) }
      end

      Result.new(schools: School.count, unmapped_schools: School.where(latitude: nil).count,
                 languages: SchoolLanguage.count, counts: SchoolLanguageCount.count, years: SchoolLanguage.years)
    end

    private

    # Returns { [cds, language, year] => english learners } and { cds => school details }
    def read_english_learners
      files = Dir[File.join(@dir, 'elsch[0-9][0-9].txt')].sort
      raise ArgumentError, "No elschYY.txt files in #{@dir}" if files.empty?

      counts = Hash.new(0)
      schools = {}
      files.each do |path|
        year = 2000 + File.basename(path)[/\d\d/].to_i
        CSV.foreach(path, col_sep: "\t", headers: true, quote_char: "\x00", encoding: 'bom|utf-8') do |row|
          next unless COUNTIES.include?(row['COUNTY'])

          english_learners = row['TOTAL_EL'].to_i
          language = LanguageNames.for(row['LC'], row['LANGUAGE'])
          next if english_learners.zero? || language.nil?

          cds = row['CDS']
          # Later files overwrite earlier ones, so schools get their latest name
          schools[cds] = { name: row['SCHOOL'], district: row['DISTRICT'], county: row['COUNTY'] }
          counts[[cds, language, year]] += english_learners
        end
      end
      [counts, schools]
    end

    # Returns { cds => { latitude:, longitude:, city: } }
    def read_locations
      locations = {}
      directory = File.join(@dir, 'pubschls.txt')
      if File.exist?(directory)
        CSV.foreach(directory, col_sep: "\t", headers: true, quote_char: "\x00", encoding: 'bom|utf-8') do |row|
          add_location(locations, row['CDSCode'], row['Latitude'], row['Longitude'], row['City'])
        end
      end
      Dir[File.join(@dir, 'schoolsites*.csv')].sort.each do |path|
        CSV.foreach(path, headers: true, encoding: 'bom|utf-8') do |row|
          add_location(locations, row['CDS Code'], row['Latitude'], row['Longitude'], row['City'])
        end
      end
      locations
    end

    def add_location(locations, cds, latitude, longitude, city)
      return if latitude.blank? || longitude.blank? || latitude.to_f.zero?

      locations[cds] = { latitude: latitude.to_f, longitude: longitude.to_f, city: city.presence }
    end

    # Inserts rows and returns { key => id }
    def insert_all(model, rows, key)
      now = Time.current
      rows.each_slice(5_000).each_with_object({}) do |slice, ids|
        attributes = slice.map { { latitude: nil, longitude: nil, city: nil }.slice(*model.column_names.map(&:to_sym)).merge(_1).merge(created_at: now, updated_at: now) }
        model.insert_all!(attributes, returning: [:id, key]).each { |row| ids[row[key.to_s]] = row['id'] }
      end
    end
  end
end
