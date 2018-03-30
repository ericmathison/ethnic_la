require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test 'every language in Language.list has an id and a name' do
    assert Language.list.first.has_key?(:id)
    assert Language.list.first.has_key?(:name)
  end

  test 'Language.list has every stored language' do
    assert_equal Language.list.length, Language.count
  end

  test 'name attribute should be unique' do
    # using an existing fixture name
    lang = Language.new(name: languages(:chinese).name)
    refute lang.valid?
  end
end
