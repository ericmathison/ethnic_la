require 'test_helper'

class EthnicitiesTest < ActionDispatch::IntegrationTest
  test 'ethnicity page shows the group with its tracts and county totals' do
    get ethnicity_path(ethnicities(:armenian))

    assert_response :success
    assert_select '.map-title .map-group-name', 'Armenian'
    assert_select '#map-total-count', '250'
    data = JSON.parse(css_select('#map-panel').first['data-group'])
    assert_equal [[200]], data['points'].map { _1['counts'] }
    assert_equal [['Los Angeles County', 230], ['Orange County', 20]], data['table']
    assert_select '#map-year', 0
  end

  test 'every group gets a card, largest first, with region filters' do
    get ethnicity_path(ethnicities(:armenian))

    assert_equal %w[Armenian Zapotec], css_select('.footprint-card .footprint-name').map(&:text)
    assert_select ".footprint-card[data-slug=zapotec][data-category='Indigenous Americas'][title='Zapotec: 40 people']"
    assert_equal ['All', 'Indigenous Americas', 'Middle East & North Africa'], css_select('.category-filter').map(&:text)
  end

  test 'group JSON has what the page needs to switch groups in place' do
    get ethnicity_path(ethnicities(:zapotec), format: :json)

    data = response.parsed_body
    assert_equal ['Zapotec', 'people who identify as Zapotec', [40]], data.values_at('name', 'count_label', 'totals')
    assert_equal ['Census tract 2119, Los Angeles County'], data['points'].map { "#{_1['name']}, #{_1['district']}" }
  end

  test 'the ethnicity map link opens the default group, and unknown groups are not found' do
    get ethnicities_path
    assert_redirected_to ethnicity_path('armenian')

    get ethnicity_path('klingon')
    assert_response :not_found
  end

  test 'the menu marks the ethnicity map as the current page' do
    get ethnicity_path(ethnicities(:armenian))

    assert_select '#nav-ethnicity-map.active[aria-current="page"]', 'Ethnicity Map'
    assert_select '#nav-language-map.active', 0
    assert_select '#nav-religions strong', 0
  end
end
