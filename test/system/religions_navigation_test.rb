require 'application_system_test_case'

class ReligionsNavigationTest < ApplicationSystemTestCase
  test 'visitors reach a religion page from the menu and see its map' do
    visit root_path
    assert_selector '#nav-religions', text: 'Religion: Christianity'
    find('#nav-religions').click
    within('.dropdown-menu') do
      assert_no_text 'Other'
      click_on 'Buddhism'
    end

    assert_selector 'h2', text: 'Buddhism - Los Angeles Area Religious Centers'
    assert_selector '#nav-religions', text: 'Religion: Buddhism'
    assert_selector '.heatmap.mapboxgl-map'
    assert_text 'Verified Temple'
    assert_no_text 'Missing Center'
  end

  test 'admins see admin-only religions in the menu' do
    login_as admins(:alice)
    visit religions_path
    find('#nav-religions').click
    within('.dropdown-menu') { click_on 'Other' }

    assert_selector '#admin-only-notice'
    assert_text 'New Movement Center'
  end

  test 'Christianity in the menu returns to the ethnic churches home page' do
    visit religion_path(religions(:buddhism))
    find('#nav-religions').click
    within('.dropdown-menu') { click_on 'Christianity' }

    assert_current_path root_path
    assert_selector '#nav-religions', text: 'Religion: Christianity'
  end
end
