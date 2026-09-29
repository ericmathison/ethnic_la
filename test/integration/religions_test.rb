require 'test_helper'

class ReligionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'public religion page lists only verified centers, grouped by city' do
    get religion_path(religions(:buddhism))

    assert_response :success
    assert_select '.center-name', text: /Verified Temple/
    assert_select '.center-name', text: /Uncertain Name Temple/
    assert_select '.city-heading', text: 'Los Angeles'
    assert_select '.city-heading', text: 'Pasadena'
    assert_no_match 'Unverified House Temple', response.body
    assert_no_match 'Missing Center', response.body
  end

  test 'public religion page hides admin-only details' do
    get religion_path(religions(:buddhism))

    %w[Rev.\ Private\ Leader private@example.com Private\ visit\ note Name\ uncertain].each do |secret|
      assert_no_match secret, response.body
    end
    assert_select '.center-status', count: 0
    assert_select '.map-legend', count: 0
  end

  test 'public map only includes verified centers' do
    get religion_path(religions(:buddhism))

    points = JSON.parse(css_select('.heatmap').first['data-points'])
    assert_equal ['Verified Temple'], points.map { _1['name'] }
    assert_equal 'false', css_select('.heatmap').first['data-show-status']
  end

  test 'admin-only and unverified-only religions are hidden from the public' do
    get religion_path(religions(:other))
    assert_response :not_found

    get religion_path(religions(:jainism))
    assert_response :not_found
  end

  test 'public menu and index list only public religions' do
    get religions_path

    assert_select '.dropdown-item', text: 'Buddhism'
    assert_select '.dropdown-item', text: /Other/, count: 0
    assert_select '.dropdown-item', text: 'Jainism', count: 0
    assert_select '.language a', text: /Buddhism\s*2 centers/
  end

  test 'admin sees every center with its status and private details' do
    sign_in admins(:alice)
    get religion_path(religions(:buddhism))

    assert_select '.center-name', text: /Unverified House Temple/
    assert_select '.center-name', text: /Missing Center/
    assert_select '.center-status', text: 'Unverified'
    assert_select '.center-status', text: 'Listed but not found in person'
    assert_select '.name-uncertain', text: 'Name uncertain'
    assert_select '.admin-details .leader', text: /Rev. Private Leader/
    assert_select '.admin-details .email', text: /private@example.com/
    assert_select '.admin-details .notes', text: /Private visit note/
  end

  test 'admin map includes every mappable center with its status' do
    sign_in admins(:alice)
    get religion_path(religions(:buddhism))

    points = JSON.parse(css_select('.heatmap').first['data-points'])
    assert_equal %w[missing_center unverified_house verified_temple].map { religious_centers(_1).name }.sort, points.map { _1['name'] }.sort
    assert_equal %w[not_found unverified verified], points.map { _1['status'] }.sort
  end

  test 'admin can see admin-only religions in the menu and open them' do
    sign_in admins(:alice)
    get religion_path(religions(:other))

    assert_response :success
    assert_select '#admin-only-notice'
    assert_select '.center-name', text: /New Movement Center/
    assert_select '.dropdown-item', text: /Other/
    assert_select '.dropdown-item', text: 'Jainism'
  end

  test 'websites link out but other schemes are shown as text' do
    religious_centers(:uncertain_temple).update!(website: 'javascript:alert(1)')
    get religion_path(religions(:buddhism))

    assert_select '.website a[href="http://verified.example.org"][rel="noopener nofollow"]', text: 'verified.example.org'
    assert_select '.website a[href^="javascript"]', count: 0
  end
end
