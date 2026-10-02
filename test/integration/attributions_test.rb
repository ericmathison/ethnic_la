require 'test_helper'

class AttributionsTest < ActionDispatch::IntegrationTest
  test 'credits each language photo with its image and a named source' do
    get attributions_path

    assert_response :success
    assert_select '.photo-credit', YAML.load_file(Rails.root.join('config/attributions.yml')).size
    assert_select '.photo-credit', text: /Armenian/ do
      assert_select 'img.photo-credit-image[src*=armenian]'
      assert_select "a.photo-credit-source[href^='https://commons.wikimedia.org'][target=_blank]", /Wikimedia Commons/
    end
  end

  test 'every credited photo has an image' do
    YAML.load_file(Rails.root.join('config/attributions.yml')).each_key do |language|
      assert Rails.root.join('app/assets/images', "#{language.parameterize}.jpg").exist?, "No image for #{language}"
    end
  end

  test 'credits the data behind the maps' do
    get attributions_path

    assert_select '.data-credit h4', text: 'Language Map'
    assert_select '.data-credit h4', text: 'Ethnicity Map'
    assert_select ".data-credit a[href*='openstreetmap.org/copyright']"
  end
end
