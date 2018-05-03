require 'application_system_test_case'

class EditEthnicChurchTest < ApplicationSystemTestCase
  setup do
    @ethnic_church = ethnic_churches(:bazquux)
    @church_name = 'Chinese Church of Footown'
    @phone = '1234567890'
    @website = 'https://example.com/'
    @pastors_name = 'John Doe'
    @email = 'foo@example.com'
    @invalid_email = 'foo'
    @previously_assigned_language = @ethnic_church.languages.first.name
    @new_language_from_existing_fixture = languages(:english).name
    @new_language = 'foolang'
    @country = countries(:united_states).name
    @religious_background = religious_backgrounds(:catholic).persuasion
    @street = '1234 Foostreet'
    @city = 'Footown'
    @zip = '99999'
    @note = 'This is a note.'
  end

  test 'can edit an ethnic church and associated objects' do
    visit ethnic_church_path(@ethnic_church)

    click_link 'Edit'

    #ethnic church
    fill_in 'ethnic_church_name', with: @church_name
    fill_in 'ethnic_church_phone', with: @phone
    fill_in 'ethnic_church_website', with: @website
    fill_in 'ethnic_church_pastors_name', with: @pastors_name
    fill_in 'ethnic_church_email', with: @email

    find('.chosen-search-input').click
    within('.chosen-drop') do
      find('li', text: @new_language_from_existing_fixture).click
    end
    find('.chosen-search-input').click.send_keys(@new_language)
    click_link 'add_new_language'
    fill_in 'ethnic_church_country_name', with: @country
    fill_in 'ethnic_church_religious_background_persuasion', with: @religious_background

    #address
    fill_in 'ethnic_church_address_street', with: @street
    fill_in 'ethnic_church_address_city', with: @city
    fill_in 'ethnic_church_address_zip', with: @zip

    #note
    fill_in 'ethnic_church_note_content', with: @note

    click_button 'create'

    assert_selector '#church_name', text: @church_name
    assert_selector '#phone', text: @phone
    assert_selector '#website', text: @website
    assert_selector '#pastors_name', text: @pastors_name
    assert_selector '#email', text: @email
    assert_selector '#address', text: @street
    assert_selector '#address', text: @city
    assert_selector '#address', text: @zip
    assert_selector '#language', text: @new_language_from_existing_fixture
    assert_selector '#language', text: @new_language
    assert_selector '#country', text: @country
    assert_selector '#religious_background', text: @religious_background
    assert_selector '#note', text: @note
    assert_selector '#notice', text: 'Successfully updated Ethnic Church'
  end

  test 'edit page correctly retrieves existing values' do
    visit edit_ethnic_church_path(@ethnic_church)

    church_name = find('#ethnic_church_name').value
    phone = find('#ethnic_church_phone').value
    website = find('#ethnic_church_website').value
    pastors_name = find('#ethnic_church_pastors_name').value
    email = find('#ethnic_church_email').value
    languages = find('#ethnic_church_language_name', visible: false).value
    country = find('#ethnic_church_country_name').value
    religious_background = find('#ethnic_church_religious_background_persuasion').value
    street = find('#ethnic_church_address_street').value
    city = find('#ethnic_church_address_city').value
    zip = find('#ethnic_church_address_zip').value
    note = find('#ethnic_church_note_content').value

    assert_equal church_name, @ethnic_church.name
    assert_equal phone, @ethnic_church.phone
    assert_equal website, @ethnic_church.website
    assert_equal pastors_name, @ethnic_church.pastors_name
    assert_equal email, @ethnic_church.email
    assert_equal country, @ethnic_church.country.name
    @ethnic_church.languages.pluck(:name).each do |lang|
      assert_includes languages, lang
    end
    assert_equal religious_background, @ethnic_church.religious_background.persuasion
    assert_equal street, @ethnic_church.address.street
    assert_equal city, @ethnic_church.address.city
    assert_equal zip, @ethnic_church.address.zip
    assert_equal note, @ethnic_church.note.content
  end

  test 'editing an ethnic church does not create a new record' do
    Capybara.current_driver = :rack_test
    count_before = EthnicChurch.where(name: @ethnic_church.name).count
    visit edit_ethnic_church_path(@ethnic_church)
    click_button 'create'
    count_after = EthnicChurch.where(name: @ethnic_church.name).count
    assert_equal count_before, count_after
  end

  test 'edit page displays error for invalid input' do
    visit edit_ethnic_church_path(@ethnic_church)
    fill_in 'ethnic_church_email', with: @invalid_email
    click_button 'create'
    assert_selector '#alert', text: 'Email is invalid'
  end

  test 'no error for empty email on edit page' do
    empty_string = ''
    visit edit_ethnic_church_path(@ethnic_church)
    fill_in 'ethnic_church_email', with: empty_string
    click_button 'create'
    assert_selector '#notice', text: 'Successfully updated Ethnic Church'
  end
end
