require 'test_helper'

class ContactEmailTest < ActionDispatch::IntegrationTest
  test 'the footer links to the contact address without spelling it out in the HTML' do
    [attributions_path, school_language_path(school_languages(:armenian)), ethnicity_path(ethnicities(:armenian))].each do |path|
      get path

      assert_select 'footer a.email-link[data-user=contact][data-domain=?][data-text=Contact]', 'ethnicla.com'.reverse
      assert_no_match(/contact@|mailto:/, response.body, "#{path} shows the address to harvesters")
    end
    assert_select '.map-contact', 0
  end
end
