require 'test_helper'

class LanguagesPageTest < ActionDispatch::IntegrationTest
  test 'language page lists ethnic churches of given language and no others' do
    get language_path(languages(:chinese).id)

    assert_select '.language-name', languages(:chinese).name
    assert_select '.language-name', {count: 0, text: languages(:english).name}
  end
end
