require 'test_helper'

class EthnicChurchesControllerTest < ActionDispatch::IntegrationTest
  fixtures :ethnic_churches

  test "#index" do
    get '/'

    assert_equal 200, status

    assert_select 'table' do
      assert_select 'td', ethnic_churches(:foobar).name
    end
  end
end
