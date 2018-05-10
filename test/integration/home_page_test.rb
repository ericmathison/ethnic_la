require 'test_helper'

class HomePageTest < ActionDispatch::IntegrationTest
  test 'links to pages of ethnic churches by language' do
    get '/'

    assert_select 'a', languages(:chinese).name
    assert_select 'a', languages(:english).name
    assert_select "a:match('href', ?)", language_path(languages(:chinese).id)
  end

  test 'home page does not break when ethnic church is missing language' do
    ec = ethnic_churches(:foobar)
    ec.languages.destroy_all

    get '/'

    assert ec.languages.empty?
  end
end
