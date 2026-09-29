require 'test_helper'

class ReligionTest < ActiveSupport::TestCase
  test 'generates a URL slug from the name' do
    assert_equal 'bahai-faith', Religion.create!(name: "Bahá'í Faith").slug
    assert_equal 'bahai-faith', Religion.find_by(slug: 'bahai-faith').to_param
  end

  test 'public list excludes admin-only religions and those without verified centers' do
    assert_equal ['Buddhism'], Religion.visible_to(false).map(&:name)
    assert_equal %w[Buddhism Jainism Other], Religion.visible_to(true).map(&:name)
  end
end
