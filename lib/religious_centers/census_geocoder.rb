require 'csv'
require 'json'
require 'tempfile'
require 'typhoeus'

module ReligiousCenters
  # Geocodes addresses with the U.S. Census Bureau batch geocoder, which is free,
  # needs no API key, and allows storing results. Results are cached on disk so
  # re-running the cleanup doesn't repeat lookups.
  class CensusGeocoder
    URL = 'https://geocoding.geo.census.gov/geocoder/locations/addressbatch'
    Result = Struct.new(:match, :exact, :matched_address, :latitude, :longitude, keyword_init: true) do
      def matched? = match == 'Match'
      def zip = matched_address.to_s[/\b(\d{5})\z/, 1]
    end

    def initialize(cache_path:)
      @cache_path = cache_path
      @cache = File.exist?(cache_path) ? JSON.parse(File.read(cache_path)) : {}
    end

    # addresses: { key => { street:, city:, zip: } }. Returns { key => Result }.
    #
    # Addresses that don't match with the city and ZIP are retried with only the
    # ZIP, then only the city, since the spreadsheet often names a neighborhood
    # ("Phillips Ranch") or has a mistyped ZIP. Retried matches count as approximate.
    def geocode(addresses)
      attempts = [
        ->(a) { [query_street(a[:street]), a[:city], 'CA', a[:zip]] },
        ->(a) { a[:zip].to_s.match?(/\A9\d{4}/) ? [query_street(a[:street]), '', 'CA', a[:zip].to_s[0, 5]] : nil },
        ->(a) { a[:city].present? ? [query_street(a[:street]), a[:city], 'CA', ''] : nil }
      ]
      results = {}
      attempts.each_with_index do |attempt, index|
        pending = addresses.reject { |key, _| results[key]&.matched? }
        queries = pending.to_h { |key, address| [key, attempt.call(address)] }.compact
        lookup(queries.values).then do |found|
          queries.each do |key, query|
            result = found.fetch(query)
            result.exact = false if index.positive?
            results[key] = result if result.matched? || !results.key?(key)
          end
        end
      end
      addresses.keys.to_h { |key| [key, results.fetch(key) { Result.new(match: 'No_Match') }] }
    end

    # Suite/unit numbers, mailbox numbers, and letter suffixes confuse the
    # geocoder and don't change the map location.
    def query_street(street)
      street.to_s.sub(/[\s,]*(?:#|\b(?:suite|ste\.?|unit|apt\.?|bldg\.?|room|box)\b).*\z/i, '').sub(/\A(\d+)[A-Za-z]\b/, '\\1').strip
    end

    private

    def lookup(queries)
      missing = queries.uniq.reject { |query| @cache.key?(cache_key(query)) }
      fetch(missing).each { |query, result| @cache[cache_key(query)] = result } if missing.any?
      File.write(@cache_path, JSON.pretty_generate(@cache))
      queries.to_h { |query| [query, Result.new(**@cache.fetch(cache_key(query), { 'match' => 'No_Match' }).transform_keys(&:to_sym))] }
    end

    def cache_key(query) = query.join('|')

    def fetch(queries)
      file = Tempfile.new(['addresses', '.csv'])
      queries.each_with_index { |query, index| file.write(CSV.generate_line([index, *query])) }
      file.close

      response = Typhoeus.post(URL, body: { benchmark: 'Public_AR_Current', addressFile: File.open(file.path) }, timeout: 600)
      raise "Census geocoder failed: HTTP #{response.code} #{response.return_message}" unless response.success?

      parse(response.body).to_h { |index, result| [queries.fetch(index), result] }
    ensure
      file&.unlink
    end

    def parse(body)
      CSV.parse(body).filter_map do |id, _input, match, exact, matched_address, coordinates, *|
        lng, lat = coordinates.to_s.split(',').map(&:to_f)
        [id.to_i, { 'match' => match, 'exact' => exact == 'Exact', 'matched_address' => matched_address,
                    'latitude' => lat, 'longitude' => lng }]
      end
    end
  end
end
