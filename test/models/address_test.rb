require 'test_helper'

class AddressTest < ActiveSupport::TestCase
  test 'Address#full_address returns formatted address' do
    addr = addresses(:los_angeles)
    expected_address =  "#{addr.street}\n#{addr.city}, CA #{addr.zip}"
    assert_equal expected_address, addr.full_address
  end

  test 'Address#full_address returns "CA" when all fields are nil' do
    addr = Address.new
    expected_address =  'CA'
    assert_equal expected_address, addr.full_address
  end

  test 'Address#full_address returns "CA" when all strings are blank' do
    addr = Address.new
    addr.street = ''
    addr.city = ''
    addr.zip = ''
    expected_address =  'CA'
    assert_equal expected_address, addr.full_address
  end

  test 'Address#full_address returns "street\n city, CA" if street and city are present but zip is missing' do
    addr = Address.new
    street = '123 Foo St.'
    city = 'Foocity'
    addr.street = street
    addr.city = city
    expected_address = "#{street}\n#{city}, CA"
    assert_equal expected_address, addr.full_address
    addr.zip = ''
    assert_equal expected_address, addr.full_address
  end

  test 'Address#full_address returns "city, CA" when only city is present' do
    addr = Address.new
    city = 'Footown'
    addr.city = city
    expected_address = "#{city}, CA"
    assert_equal expected_address, addr.full_address
  end
end
