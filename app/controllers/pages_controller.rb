class PagesController < ApplicationController
  # Names for the sites the language tile photos come from
  PHOTO_SOURCES = {
    'commons.wikimedia.org' => 'Wikimedia Commons', 'upload.wikimedia.org' => 'Wikimedia Commons',
    'en.wikipedia.org' => 'Wikipedia', 'www.flickr.com' => 'Flickr', 'pxhere.com' => 'pxhere',
    'pixabay.com' => 'Pixabay', 'pixnio.com' => 'Pixnio', 'www.maxpixel.net' => 'Max Pixel', 'libreshot.com' => 'LibreShot'
  }.freeze

  def attributions
    @photo_credits = YAML.load_file('config/attributions.yml').map do |language, url|
      host = URI(url).host
      { language: language.titleize, image: "#{language.parameterize}.jpg", url: url,
        source: PHOTO_SOURCES.fetch(host, host.delete_prefix('www.')) }
    end
  end
end
