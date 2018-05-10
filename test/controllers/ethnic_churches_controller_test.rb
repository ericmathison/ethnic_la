require 'test_helper'

class EthnicChurchesControllerTest < ActionDispatch::IntegrationTest
  test '#index does not error' do
    get '/'

    assert_equal 200, status
  end
end
