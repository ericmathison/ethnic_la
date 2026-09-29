require 'test_helper'

class ReligiousCenterTest < ActiveSupport::TestCase
  test 'only verified centers are visible to the public' do
    assert ReligiousCenter.visible_to(false).all?(&:verified?)
    assert_equal ReligiousCenter.count, ReligiousCenter.visible_to(true).count
  end

  test 'rejects unknown statuses' do
    assert_not ReligiousCenter.new(name: 'X', status: 'closed').valid?
  end

  test 'full address' do
    assert_equal "100 Main St\nLos Angeles, CA 90012", religious_centers(:verified_temple).full_address
    assert_equal "Los Angeles, CA", religious_centers(:other_center).full_address
  end
end
