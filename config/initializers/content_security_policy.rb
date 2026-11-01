# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.object_src  :none
    policy.script_src  :self, 'https://api.mapbox.com'
    # Mapbox GL and Bootstrap set inline styles.
    policy.style_src   :self, :unsafe_inline, 'https://api.mapbox.com', 'https://fonts.googleapis.com'
    policy.font_src    :self, 'https://fonts.gstatic.com'
    policy.img_src     :self, :data, :blob, 'https://*.mapbox.com'
    policy.connect_src :self, 'https://*.mapbox.com'
    # Mapbox GL runs its workers from blob: URLs.
    policy.worker_src  :blob
    policy.child_src   :blob
  end
end
