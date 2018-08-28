require 'cgi'
require 'json'
require 'typhoeus'

class Geocoder
  attr_reader :address, :api_key

  def initialize(address, api_key)
    @address = CGI.escape(address)
    @api_key = api_key
  end

  def url
    "https://api.geocod.io/v1.3/geocode?q=#{address}&api_key=#{api_key}"
  end

  def request_results
    return @results if @results
    response = Typhoeus.get(url)
    @results = response.body if response.success?
  end

  def latitude
    request_results
    lat = JSON.parse(@results).dig('results', 0, 'location', 'lat')
    lat.to_f if lat
  end

  def longitude
    request_results
    lng = JSON.parse(@results).dig('results', 0, 'location', 'lng')
    lng.to_f if lng
  end
end
