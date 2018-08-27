require 'test_helper'
require 'geocoder'

class GeocoderTest < ActiveSupport::TestCase
  test 'given an address and api key, #url properly generates request url' do
    address = '789 Foo St., Bar Town CA'
    api_key = '1234'
    url = Geocoder.new(address, api_key).url
    expected_url = 'https://api.geocod.io/v1.3/geocode?q=789+Foo+St.%2C+Bar+Town+CA&api_key=1234'
    assert_equal expected_url, url
  end

  test '#latitude and #longitude parse respective values' do
    address = '1 World Way, Los Angeles CA'

    results = '{"input":{"address_components":{"number":"1","street":"World","suffix":"Way","formatted_street":"World Way","city":"Los Angeles","state":"CA","country":"US"},"formatted_address":"1 World Way, Los Angeles, CA"},"results":[{"address_components":{"number":"1","street":"World","suffix":"Way","formatted_street":"World Way","city":"Los Angeles","county":"Los Angeles County","state":"CA","zip":"90045","country":"US"},"formatted_address":"1 World Way, Los Angeles, CA 90045","location":{"lat":33.94469,"lng":-118.39817},"accuracy":1,"accuracy_type":"rooftop","source":"City of Los Angeles"}]}'

    geocoder = Geocoder.new(address, '')
    geocoder.instance_variable_set(:@results, results)

    assert_in_delta geocoder.latitude, 33.94469, 0.001
    assert_in_delta geocoder.longitude, -118.39817, 0.001
  end
end
