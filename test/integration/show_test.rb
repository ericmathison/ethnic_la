require 'test_helper'

class HomePageTest < ActionDispatch::IntegrationTest
  test 'displays ethnic church record' do
    ec = ethnic_churches(:foobar)

    get ethnic_church_path(ec.id)

    assert_select 'p', { text: ec.name }
    assert_select 'p', { text: ec.phone }
    assert_select 'p', { text: ec.website }
    assert_select 'p', { text: ec.pastors_name }
    assert_select 'p', { text: ec.email }
    assert_select 'p', { text: ec.address.street }
    assert_select 'p', { text: ec.language.name }
    assert_select 'p', { text: ec.country.name }
    assert_select 'p', { text: ec.religious_background.persuasion }
  end
end
