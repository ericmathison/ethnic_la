require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test "Language.list" do
    cn = languages(:chinese)
    en = languages(:english)
    array_of_hashes = [{id: cn.id, name: cn.name}, {id: en.id, name: en.name}]

    assert_equal Language.list, array_of_hashes
  end

  test 'name attribute should be unique' do
    # using an existing fixture name
    lang = Language.new(name: languages(:chinese).name)
    refute lang.valid?
  end
end
