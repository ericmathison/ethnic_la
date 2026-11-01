require 'test_helper'

class ContentSecurityPolicyTest < ActionDispatch::IntegrationTest
  test 'pages send a content security policy' do
    get '/'

    policy = response.headers['Content-Security-Policy']
    assert_includes policy, "default-src 'self'"
    assert_includes policy, "object-src 'none'"
    assert_includes policy, "frame-ancestors 'none'"
    assert_includes policy, "script-src 'self' https://api.mapbox.com;"
  end
end
