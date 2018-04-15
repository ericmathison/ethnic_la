require 'test_helper'

class EthnicChurchBuilderTest < ActiveSupport::TestCase
  test 'EthnicChurchBuilder.instantiate' do
    params = ActionController::Parameters.new({
      ethnic_church: {
        name: 'Foobar Korean Church',
        phone: '123-456-7890',
        website: 'https://example.com',
        pastors_name: 'Peter Kim',
        email: 'contact@example.com'
      },
      language: {
        name: ['Korean', 'English']
      },
      country: {
        name: 'Korea'
      },
      religious_background: {
        persuasion: 'Protestant'
      },
      address: {
        street: '1234 Foo St.',
        city: 'Los Angeles',
        zip: '90000'
      },
      note: {
        content: 'Look! A note!'
      }
    })

    ec = EthnicChurchBuilder.instantiate(params)

    assert_equal ec.name, params[:ethnic_church][:name]
    assert_equal ec.phone, params[:ethnic_church][:phone]
    assert_equal ec.website, params[:ethnic_church][:website]
    assert_equal ec.pastors_name, params[:ethnic_church][:pastors_name]
    assert_equal ec.email, params[:ethnic_church][:email]

    params[:language][:name].each do |lang_name|
      assert_includes ec.languages.map(&:name), lang_name
    end

    assert_equal ec.country.name, params[:country][:name]

    assert_equal ec.religious_background.persuasion, params[:religious_background][:persuasion]

    assert_equal ec.address.street, params[:address][:street]
    assert_equal ec.address.city, params[:address][:city]
    assert_equal ec.address.zip, params[:address][:zip]

    assert_equal ec.note.content, params[:note][:content]
  end
end
