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

  test 'languages are listed alphabetically and the year can be chosen' do
    get school_language_path(school_languages(:armenian), year: 2024)

    assert_select '#school-language-total-count', '40'
    assert_select '#school-language-year-label', '2024-25'
    assert_equal ['Armenian (35)', 'Spanish (100)'], css_select('#school-language-select option').map(&:text)
    assert_select '.trend-bar.selected[data-index="0"]'
  end

  test 'the language picker redirects to the chosen language, keeping the year' do
    get school_languages_path(language: 'spanish', year: 2024)
    assert_redirected_to school_language_path('spanish', year: 2024)

    get school_languages_path
    assert_redirected_to school_language_path('arabic')
  end

  test 'unknown languages are not found' do
    get school_language_path('klingon')
    assert_response :not_found
  end

  test 'the menu links to the language map and marks it as the current page' do
    get root_path
    assert_select '#nav-language-map[href="/language-map"]', 'Language Map'
    assert_select '#nav-language-map.active', count: 0
    assert_select '#nav-religions.active'

    get school_language_path(school_languages(:armenian))
    assert_equal '/language-map/armenian', path
    assert_select '#nav-language-map.active[aria-current="page"]'
    assert_select '#nav-religions', text: 'Religion'
    assert_select '#nav-religions.active', count: 0
    assert_select '#nav-religions strong', count: 0
  end

  test 'browse page shows a card per language linking to its map' do
    school_language_counts(:white_spanish_2025).update!(english_learners: 5)
    get browse_school_languages_path

    assert_response :success
    assert_select '.language-browse > .footprint-grid .footprint-card', 1
    assert_select ".footprint-card[href='#{school_language_path('armenian', year: 2025)}']" do
      assert_select '.footprint-endonym[lang=hy]', 'Հայերեն'
      assert_select '.footprint-name', 'Armenian'
      assert_select '.footprint-count', /35/
      assert_select '.footprint-dots circle', 1
    end
    assert_select '#smaller-languages .footprint-card .footprint-name', 'Spanish'
  end

  test 'the map page links to the browse page' do
    get school_language_path(school_languages(:armenian))
    assert_select "a.browse-link[href='#{browse_school_languages_path}']"
  end
end
