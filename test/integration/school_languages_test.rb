require 'test_helper'

class SchoolLanguagesTest < ActionDispatch::IntegrationTest
  def panel_data
    JSON.parse(css_select('#language-panel').first['data-language'])
  end

  test 'language page shows the latest year with every mapped school' do
    get school_language_path(school_languages(:armenian))

    assert_response :success
    assert_select '#language-title-name', 'Armenian'
    assert_select '#language-title-endonym[lang=hy]', 'Հայերեն'
    assert_select '#school-language-total-count', '35'
    assert_select '#school-language-year-label', '2025-26'
    assert_equal '2025', css_select('#language-panel').first['data-year']

    data = panel_data
    assert_equal [2024, 2025], data['years']
    assert_equal [40, 35], data['totals']
    assert_equal [['R. D. White Elementary', [40, 30]]], data['points'].map { [_1['name'], _1['counts']] }
  end

  test 'the year can be chosen' do
    get school_language_path(school_languages(:armenian), year: 2024)

    assert_select '#school-language-total-count', '40'
    assert_select '#school-language-year-label', '2024-25'
    assert_select '.trend-bar.selected[data-index="0"]'
  end

  test 'every language gets a card, largest first, after the key that explains them' do
    get school_language_path(school_languages(:armenian))

    assert_select '.footprint-grid > :first-child.footprint-key'
    assert_equal %w[Spanish Armenian], css_select('.footprint-card .footprint-name').map(&:text)
    assert_select '[data-sort=size].active[aria-pressed=true]'
    assert_select ".footprint-card[href='#{school_language_path('armenian')}'][data-slug=armenian][title='Armenian: 35 English learners']" do
      assert_select '.footprint-endonym[lang=hy]', 'Հայերեն'
      assert_select '.footprint-count', 0
      assert_select '.footprint-dots circle', 1
    end
    assert_select '#footprint-outline path', minimum: 5
  end

  test 'language JSON has what the page needs to switch languages in place' do
    get school_language_path(school_languages(:spanish), format: :json)

    data = response.parsed_body
    assert_equal %w[Spanish spanish Español es], data.values_at('name', 'slug', 'endonym', 'lang')
    assert_equal [0, 100], data['totals']
    assert_equal [[0, 100]], data['points'].map { _1['counts'] }
  end

  test 'the language map link redirects to a language, keeping the year' do
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
  end
end
