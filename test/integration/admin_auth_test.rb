require 'test_helper'

class AdminAuthTest < ActionDispatch::IntegrationTest
  test 'throttles repeated admin sign-in attempts' do
    10.times do
      post admin_session_path, params: { admin: { email: 'alice@example.com', password: 'wrong-password' } }
      assert_response :success
    end

    post admin_session_path, params: { admin: { email: 'alice@example.com', password: 'wrong-password' } }

    assert_redirected_to new_admin_session_path
    assert_equal 'Too many attempts. Try again later.', flash[:alert]
  end

  test 'password recovery is disabled because production sends no mail' do
    post '/admins/password', params: { admin: { email: 'alice@example.com' } }

    assert_response :not_found
  end
end
