require 'application_system_test_case'

class LanguagesTest < ApplicationSystemTestCase
  test 'has pagination' do
    lang = languages(:chinese)
    visit root_path
    click_link lang.name
    click_link 'Next'
    assert_equal language_path(lang, page: 2), current_fullpath
    assert_link 'Prev', href: language_path(lang)
  end

  def current_fullpath
    URI.parse(current_url).request_uri
  end
end
