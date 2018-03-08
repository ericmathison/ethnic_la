require 'test_helper'

class AddressTest < ActiveSupport::TestCase
  test "Address#full_address" do
    addr = addresses(:los_angeles)
    expected_address =  "#{addr.street}\n#{addr.city}, #{addr.state} #{addr.zip}"

    assert_equal addr.full_address, expected_address
  end
end
