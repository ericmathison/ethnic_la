require 'test_helper'

class LanguageTest < ActiveSupport::TestCase
  test "Language.list" do
    cn = languages(:chinese)
    en = languages(:english)
    array_of_hashes = [{id: cn.id, name: cn.name}, {id: en.id, name: en.name}]

    assert_equal Language.list, array_of_hashes
  end
end
