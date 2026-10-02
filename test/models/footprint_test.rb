require 'test_helper'

class FootprintTest < ActiveSupport::TestCase
  test 'each language uses its most recent year, counting unmapped schools in the total' do
    armenian = LanguageFootprint.all.find { _1.language == school_languages(:armenian) }

    assert_equal 2025, armenian.year
    assert_equal 35, armenian.english_learners
    assert_equal 1, armenian.dots.size
    assert_equal ['hy', 'Հայերեն'], [armenian.lang, armenian.endonym]
  end

  test 'places in the same grid cell share one dot sized by their combined count' do
    dots = Footprint.dots_for([[10, 34.0, -118.0], [30, 34.0001, -118.0001], [10, 33.6, -117.5]])

    assert_equal 2, dots.size
    assert_equal 4.0, dots.max_by(&:r).r
  end

  test 'places outside the frame are left off the map' do
    assert_empty Footprint.dots_for([[10, 35.5, -118.0], [10, 34.0, -114.6]])
  end

  test 'the outline and landmarks are drawn in the frame' do
    assert_includes Footprint.outline.map { _1['name'] }, 'Los Angeles'
    Footprint.landmarks.each do |name, x, y, _anchor|
      assert x.between?(0, Footprint::WIDTH) && y.between?(0, Footprint::HEIGHT), "#{name} is outside the frame"
    end
  end

  test 'each ethnic group is drawn from its tracts' do
    armenian = EthnicityFootprint.all.find { _1.ethnicity == ethnicities(:armenian) }

    assert_equal 1, armenian.dots.size
  end
end
