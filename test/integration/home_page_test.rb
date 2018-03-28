require 'test_helper'

class HomePageTest < ActionDispatch::IntegrationTest
  test 'links to pages of ethnic churches by language' do
    get '/'

    assert_select 'a', languages(:chinese).name
    assert_select 'a', languages(:english).name
    assert_select "a:match('href', ?)", language_path(languages(:chinese).id)
  end

  test 'links to ethnic church show page' do
    get '/'

    assert_select 'a', ethnic_churches(:foobar).name
    assert_select 'a', ethnic_churches(:bazquux).name
    assert_select "a:match('href', ?)", ethnic_church_path(ethnic_churches(:foobar).id)
    assert_select "a:match('href', ?)", ethnic_church_path(ethnic_churches(:bazquux).id)
  end
end
