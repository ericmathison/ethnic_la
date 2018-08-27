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
    JSON.parse(@results)['results'][0]['location']['lat'].to_f
  end

  def longitude
    request_results
    JSON.parse(@results)['results'][0]['location']['lng'].to_f
  end
end
