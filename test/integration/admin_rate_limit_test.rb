require 'test_helper'

class AdminRateLimitTest < ActionDispatch::IntegrationTest
  test 'throttles repeated admin sign-in attempts' do
    10.times do
      post admin_session_path, params: { admin: { email: 'alice@example.com', password: 'wrong-password' } }
      assert_response :success
    end

    post admin_session_path, params: { admin: { email: 'alice@example.com', password: 'wrong-password' } }

    assert_redirected_to new_admin_session_path
    assert_equal 'Too many attempts. Try again later.', flash[:alert]
  end

  test 'throttles repeated password reset requests' do
    5.times do
      post admin_password_path, params: { admin: { email: 'nobody@example.com' } }
      assert_redirected_to new_admin_session_path
    end

    post admin_password_path, params: { admin: { email: 'nobody@example.com' } }

    assert_redirected_to new_admin_password_path
    assert_equal 'Too many attempts. Try again later.', flash[:alert]
  end
end
