require 'test_helper'

class HomePageTest < ActionDispatch::IntegrationTest
  test 'displays ethnic church record' do
    ec = ethnic_churches(:foobar)

    get ethnic_church_path(ec.id)

    assert_select '#church_name', { text: ec.name }
    assert_select '#phone', { text: ec.phone }
    assert_select '#website', { text: ec.website }
    assert_select '#pastors_name', { text: ec.pastors_name }
    assert_select '#email', { text: ec.email }
    assert_select '#address', { text: ec.address.full_address }
    assert_select '#language', { text: ec.language.name }
    assert_select '#country', { text: ec.country.name }
    assert_select '#religious_background', { text: ec.religious_background.persuasion }
    assert_select '#note', { text: ec.note.content }
  end
end
