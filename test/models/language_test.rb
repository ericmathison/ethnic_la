require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test 'every language in Language.list has an id and a name' do
    assert Language.list.first.has_key?(:id)
    assert Language.list.first.has_key?(:name)
  end

  test 'Language.list has every stored language' do
    assert_equal Language.list.length, Language.count
  end

  test 'name value matches name of corresponding Language record' do
    l = Language.first
    expected_name = l.name
    actual_name = Language.list
                    .select { |languages| languages[:id] == l.id }
                    .first[:name]

    assert_equal expected_name, actual_name
  end

  test 'name attribute should be unique' do
    # using an existing fixture name
    lang = Language.new(name: languages(:chinese).name)
    refute lang.valid?
  end
end
