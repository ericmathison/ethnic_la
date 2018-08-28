require 'geocoder'

# example usage:
# $ GEOCODER_API_KEY=[api_key] rails runner lib/scripts/retrieve_coordinates.rb

number_to_process = Address.count

Address.where(latitude: nil)
  .or(Address.where(longitude: nil))
  .limit(number_to_process)
  .find_each
  .with_index(1) do |addr, i|

  # good enough for most addresses as the number of records missing important
  # address fields is minimal
  geocoder_addr = [addr.street, addr.city].join(', ') + ' CA'

  geocoder = Geocoder.new(geocoder_addr, ENV['GEOCODER_API_KEY'])
  addr.latitude = geocoder.latitude
  addr.longitude = geocoder.longitude
  addr.save

  printf "\rProcessing address number #{i}"
end
puts
