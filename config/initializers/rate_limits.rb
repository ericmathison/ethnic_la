# Throttle admin sign-in and password-reset attempts per IP to slow brute forcing.
# A process-local store keeps this working without a shared cache (the app runs a single Puma worker).
Rails.application.config.to_prepare do
  store = ActiveSupport::Cache::MemoryStore.new

  Devise::SessionsController.rate_limit to: 10, within: 3.minutes, only: :create, store: store,
                                        with: -> { redirect_to new_admin_session_path, alert: 'Too many attempts. Try again later.' }
  Devise::PasswordsController.rate_limit to: 5, within: 15.minutes, only: :create, store: store,
                                         with: -> { redirect_to new_admin_password_path, alert: 'Too many attempts. Try again later.' }
end
