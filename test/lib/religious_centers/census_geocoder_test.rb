require 'test_helper'
require Rails.root.join('lib/religious_centers')

class ReligiousCenters::CensusGeocoderTest < ActiveSupport::TestCase
  setup do
    @cache = Tempfile.new(['geocode_cache', '.json'])
    @cache.write('{}')
    @cache.close
    @geocoder = ReligiousCenters::CensusGeocoder.new(cache_path: @cache.path)
  end

  teardown do
    @cache.unlink
    Typhoeus::Expectation.clear
  end

  test 'strips suite, unit, mailbox, and letter suffixes from the query street' do
    assert_equal '10231 Slater Av', @geocoder.query_street('10231 Slater Av #204')
    assert_equal '9300 Gardenia St', @geocoder.query_street('9300 Gardenia St Suite B3')
    assert_equal '3017 Santa Monica Blvd', @geocoder.query_street('3017 Santa Monica Blvd Box 372')
    assert_equal '1001 Colorado Ave', @geocoder.query_street('1001A Colorado Ave')
  end

  test 'parses batch results, retries misses with the ZIP only, and caches results' do
    responses = [
      %("0","1 Main St, Los Angeles, CA, 90012","Match","Exact","1 MAIN ST, LOS ANGELES, CA, 90012","-118.24,34.05","1","L"\n) +
        %("1","2 Oak St, Phillips Ranch, CA, 91766","No_Match"\n),
      %("0","2 Oak St, , CA, 91766","Match","Non_Exact","2 OAK ST, POMONA, CA, 91766","-117.75,34.05","2","R"\n)
    ]
    Typhoeus.stub(ReligiousCenters::CensusGeocoder::URL) { Typhoeus::Response.new(code: 200, body: responses.shift) }

    results = @geocoder.geocode(
      a: { street: '1 Main St', city: 'Los Angeles', zip: '90012' },
      b: { street: '2 Oak St', city: 'Phillips Ranch', zip: '91766' }
    )

    assert results[:a].matched? && results[:a].exact
    assert_in_delta 34.05, results[:a].latitude
    assert results[:b].matched?
    assert_not results[:b].exact, 'a retried match is approximate'
    assert_equal '91766', results[:b].zip
    assert_equal 3, JSON.parse(File.read(@cache.path)).size
  end
end
