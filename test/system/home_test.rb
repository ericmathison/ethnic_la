require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase
  test 'has pagination' do
    visit root_path
    click_link 'Next'
    assert_equal root_path(page: 2), current_fullpath
    assert_link 'Prev', href: root_path
  end

  def current_fullpath
    URI.parse(current_url).request_uri
  end
end
