require 'test_helper'

class CountryTest < ActiveSupport::TestCase
  test 'name attribute should be unique' do
    # using an existing fixture name
    lang = Country.new(name: countries(:china).name)
    refute lang.valid?
  end
end
