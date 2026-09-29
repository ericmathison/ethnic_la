require 'test_helper'
require Rails.root.join('lib/religious_centers')
require Rails.root.join('lib/religious_centers/importer')

class ReligiousCenters::ImporterTest < ActiveSupport::TestCase
  def records
    [
      { row: 100, name: 'Imported Temple', city: 'Los Angeles', status: 'verified', religions: %w[Buddhism Taoism],
        leader: 'Private', latitude: 34.0, longitude: -118.0, name_uncertain: false },
      { row: 101, name: 'Vague Group', city: 'Irvine', status: 'unverified', religions: ['Other'], name_uncertain: false }
    ]
  end

  test 'creates centers, religions, and memberships, and is safe to re-run' do
    2.times { ReligiousCenters::Importer.new(records).import }

    center = ReligiousCenter.find_by!(source_row: 100)
    assert_equal %w[Buddhism Taoism], center.religions.map(&:name).sort
    assert_equal 'Private', center.leader
    assert_equal 1, ReligiousCenter.where(source_row: 100).count
    assert Religion.find_by!(name: 'Other').admin_only
    assert_not Religion.find_by!(name: 'Taoism').admin_only
  end

  test 'removes imported centers that are no longer in the data' do
    stale_row = religious_centers(:verified_temple).source_row
    ReligiousCenters::Importer.new(records).import

    assert_nil ReligiousCenter.find_by(source_row: stale_row)
    assert_equal [100, 101], ReligiousCenter.order(:source_row).pluck(:source_row)
  end
end
