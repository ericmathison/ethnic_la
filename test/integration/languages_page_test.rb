require 'test_helper'

class LanguagesPageTest < ActionDispatch::IntegrationTest
  test 'language page lists ethnic churches of given language and no others' do
    get language_path(languages(:chinese))

    assert_select '.language-name', languages(:chinese).name
    assert_select '.language-name', {count: 0, text: languages(:english).name}
  end

  test 'links to ethnic church show page' do
    get language_path(languages(:chinese))

    assert_select 'a', ethnic_churches(:bazquux).name
    assert_select "a:match('href', ?)", ethnic_church_path(ethnic_churches(:bazquux))
  end

end
