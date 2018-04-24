require 'test_helper'

class EthnicChurchBuilderTest < ActiveSupport::TestCase
  test 'EthnicChurchBuilder.instantiate assigns associated objects' do
    ethnic_church = ethnic_churches(:foobar)
    languages = [languages(:chinese), languages(:english)]
    country = countries(:china)
    religious_background = religious_backgrounds(:protestant)
    address = addresses(:los_angeles)
    note = notes(:one)

    ec = EthnicChurchBuilder.instantiate(
      ethnic_church: ethnic_church,
      languages: languages,
      country: country,
      religious_background: religious_background,
      address: address,
      note: note
    )

    assert_equal ec.name, ethnic_church.name
    assert_equal ec.phone, ethnic_church.phone
    assert_equal ec.website, ethnic_church.website
    assert_equal ec.pastors_name, ethnic_church.pastors_name
    assert_equal ec.email, ethnic_church.email

    languages.each do |lang|
      assert_includes ec.languages.map(&:name), lang.name
    end

    assert_equal ec.country.name, country.name

    assert_equal ec.religious_background.persuasion, religious_background.persuasion

    assert_equal ec.address.street, address.street
    assert_equal ec.address.city, address.city
    assert_equal ec.address.zip, address.zip

    assert_equal ec.note.content, note.content
  end
end
