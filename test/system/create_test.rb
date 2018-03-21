require "application_system_test_case"

class CreateTest < ApplicationSystemTestCase
  test 'successfully creates an ethnic church and associated objects' do
    visit new_ethnic_church_path

    church_name = 'Chinese Church of Footown'
    phone = '1234567890'
    website = 'https://example.com/'
    pastors_name = 'John Doe'
    email = 'foo@example.com'

    #use an existing language name to ensure application can handle re-using
    #language names
    language = languages(:chinese).name

    #use an existing country name
    country = countries(:china).name

    #use an existing religious_background name
    religious_background = religious_backgrounds(:protestant).persuasion

    street = '1234 Foostreet'
    city = 'Footown'
    zip = '99999'
    note = 'This is a note.'

    #ethnic church
    fill_in 'ethnic_church_name', with: church_name
    fill_in 'ethnic_church_phone', with: phone
    fill_in 'ethnic_church_website', with: website
    fill_in 'ethnic_church_pastors_name', with: pastors_name
    fill_in 'ethnic_church_email', with: email

    select language, from: 'language_name'
    fill_in 'country_name', with: country
    fill_in 'religious_background_persuasion', with: religious_background

    #address
    fill_in 'address_street', with: street
    fill_in 'address_city', with: city
    fill_in 'address_zip', with: zip

    #note
    fill_in 'note_content', with: note

    click_button 'create'

    ec = EthnicChurch.where(name: church_name).first

    assert_equal ec.name, church_name
    assert_equal ec.phone, phone
    assert_equal ec.website, website
    assert_equal ec.pastors_name, pastors_name
    assert_equal ec.email, email
    assert_equal ec.languages.first.name, language
    assert_equal ec.country.name, country
    assert_equal ec.religious_background.persuasion, religious_background
    assert_equal ec.address.street, street
    assert_equal ec.address.city, city
    assert_equal ec.address.zip, zip

    assert_equal find('#notice').text, 'Successfully added new Ethnic Church'
  end
end
