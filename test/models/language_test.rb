require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test 'name attribute should be unique' do
    # using an existing fixture name
    lang = Language.new(name: languages(:chinese).name)
    refute lang.valid?
  end
end
