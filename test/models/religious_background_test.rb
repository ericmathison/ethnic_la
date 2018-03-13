require 'test_helper'

class ReligiousBackgroundTest < ActiveSupport::TestCase
  test 'persuasion attribute should be unique' do
    # using an existing fixture name
    religious_background = ReligiousBackground.new(persuasion: religious_backgrounds(:protestant).persuasion)
    refute religious_background.valid?
  end
end
