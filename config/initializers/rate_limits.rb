# Throttle admin sign-in attempts per IP to slow brute forcing.
# A process-local store keeps this working without a shared cache (the app runs a single Puma worker).
ADMIN_SIGN_IN_RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

Rails.application.config.to_prepare do
  Devise::SessionsController.rate_limit to: 10, within: 3.minutes, only: :create, store: ADMIN_SIGN_IN_RATE_LIMIT_STORE,
                                        with: -> { redirect_to new_admin_session_path, alert: 'Too many attempts. Try again later.' }
end
