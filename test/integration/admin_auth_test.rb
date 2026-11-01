require 'test_helper'

class AdminAuthTest < ActionDispatch::IntegrationTest
  setup do
    ADMIN_SIGN_IN_RATE_LIMIT_STORE.clear
    @admin = Admin.create!(email: 'carol@example.com', password: 'correct-horse-battery')
  end

  test 'throttles repeated admin sign-in attempts' do
    10.times do
      sign_in_with 'nobody@example.com', 'wrong-password'
      assert_response :success
    end

    sign_in_with 'nobody@example.com', 'wrong-password'

    assert_redirected_to new_admin_session_path
    assert_equal 'Too many attempts. Try again later.', flash[:alert]
  end

  test 'locks the account after repeated failed sign-ins without revealing it' do
    10.times { sign_in_with @admin.email, 'wrong-password' }
    assert @admin.reload.access_locked?

    ADMIN_SIGN_IN_RATE_LIMIT_STORE.clear
    sign_in_with @admin.email, 'correct-horse-battery'

    assert_response :success
    assert_equal 'Invalid email or password.', flash[:alert]
  end

  test 'unlocks the account after an hour' do
    @admin.lock_access!

    travel 61.minutes do
      sign_in_with @admin.email, 'correct-horse-battery'
    end

    assert_redirected_to root_path
  end

  test 'password recovery and email unlocks are disabled because production sends no mail' do
    post '/admins/password', params: { admin: { email: @admin.email } }
    assert_response :not_found

    post '/admins/unlock', params: { admin: { email: @admin.email } }
    assert_response :not_found
  end

  private

  def sign_in_with(email, password)
    post admin_session_path, params: { admin: { email: email, password: password } }
  end
end
