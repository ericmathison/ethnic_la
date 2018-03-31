require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :webkit

  Capybara::Webkit.configure do |config|
    config.block_unknown_urls
  end
end
