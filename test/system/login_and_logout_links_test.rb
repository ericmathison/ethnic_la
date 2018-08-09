require 'application_system_test_case'

class LoginAndLogoutLinksTest < ApplicationSystemTestCase
  setup do
    @admin = admins(:alice)
  end

  test 'home page shows logout links when signed in' do
    login_as @admin
    visit root_path

    assert_selector '#logout', text: 'Logout'
    refute_selector '#login'
  end

  test 'home page shows login links when signed out' do
    visit root_path

    refute_selector '#logout'
    assert_selector '#login', text: 'Admin Login'
  end

  test 'login page does not show login or logout links' do
    visit new_admin_session_path

    refute_selector '#logout'
    refute_selector '#login'
  end
end
