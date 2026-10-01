require 'test_helper'

class SchoolLanguagesTest < ActionDispatch::IntegrationTest
  test 'language page shows the latest year with every mapped school' do
    get school_language_path(school_languages(:armenian))

    assert_response :success
    assert_select 'h2', 'Armenian - Los Angeles Area English Learners'
    assert_select '#school-language-total-count', '35'
    assert_select '#school-language-year-label', '2025-26'
    assert_select '#school-language-select option[selected]', 'Armenian (35)'

    map = css_select('.school-language-map').first
    assert_equal [2024, 2025], JSON.parse(map['data-years'])
    assert_equal '2025', map['data-year']
    points = JSON.parse(map['data-points'])
    assert_equal [['R. D. White Elementary', [40, 30]]], points.map { [_1['name'], _1['counts']] }
  end

  test 'languages are listed largest first and the year can be chosen' do
    get school_language_path(school_languages(:armenian), year: 2024)

    assert_select '#school-language-total-count', '40'
    assert_select '#school-language-year-label', '2024-25'
    assert_equal ['Spanish (100)', 'Armenian (35)'], css_select('#school-language-select option').map(&:text)
    assert_select '.trend-bar.selected[data-index="0"]'
  end

  test 'the language picker redirects to the chosen language, keeping the year' do
    get school_languages_path(language: 'spanish', year: 2024)
    assert_redirected_to school_language_path('spanish', year: 2024)

    get school_languages_path
    assert_redirected_to school_language_path('spanish')
  end

  test 'unknown languages are not found' do
    get school_language_path('klingon')
    assert_response :not_found
  end
end
