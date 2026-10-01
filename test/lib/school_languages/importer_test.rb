require 'test_helper'
require Rails.root.join('lib/school_languages/importer')

class SchoolLanguages::ImporterTest < ActiveSupport::TestCase
  HEADER = %w[CDS COUNTY DISTRICT SCHOOL LC LANGUAGE GR_TK GR_KN GR_1 GR_2 GR_3 GR_4 GR_5 GR_6 GR_7 GR_8 GR_9 GR_10
              GR_11 GR_12 UNGR TOTAL_EL].freeze

  setup do
    @dir = Dir.mktmpdir
  end

  teardown do
    FileUtils.remove_entry(@dir)
  end

  def write_year(name, rows)
    lines = [HEADER] + rows.map { |cds, county, school, code, language, total| [cds, county, 'Glendale Unified', school, code, language] + [''] * 15 + [total] }
    File.write(File.join(@dir, name), lines.map { _1.join("\t") }.join("\r\n") + "\r\n")
  end

  def write_sites(rows)
    CSV.open(File.join(@dir, 'schoolsites2526.csv'), 'w') do |csv|
      csv << ['CDS Code', 'School Name', 'City', 'Latitude', 'Longitude']
      rows.each { csv << _1 }
    end
  end

  test 'imports LA-area counts across both language code schemes' do
    write_year('elsch22.txt', [
      ['19645000000001', 'Los Angeles', 'Old Name Elementary', '12', 'Armenian', '40'],
      ['19645000000001', 'Los Angeles', 'Old Name Elementary', '99', 'Other non-English languages', '3'],
      ['19645000000002', 'Los Angeles', 'Closed Elementary', '12', 'Armenian', '5'],
      ['01100170000003', 'Alameda', 'Oakland School', '12', 'Armenian', '9']
    ])
    write_year('elsch25.txt', [
      ['19645000000001', 'Los Angeles', 'R. D. White Elementary', 'arm', 'Armenian', '30'],
      ['19645000000001', 'Los Angeles', 'R. D. White Elementary', 'phi', 'Philippine languages', '2'],
      ['19645000000001', 'Los Angeles', 'R. D. White Elementary', 'tgl', 'Tagalog', '1'],
      ['19645000000001', 'Los Angeles', 'R. D. White Elementary', 'kor', 'Korean', '0']
    ])
    write_sites([['19645000000001', 'R. D. White Elementary', 'Glendale', '34.15', '-118.25']])

    result = SchoolLanguages::Importer.import(@dir)

    assert_equal 2, result.schools
    assert_equal 1, result.unmapped_schools
    assert_equal [2022, 2025], result.years
    assert_equal ['Armenian', 'Filipino (Tagalog)'], SchoolLanguage.order(:name).pluck(:name)

    white = School.find_by!(cds_code: '19645000000001')
    assert_equal 'R. D. White Elementary', white.name
    assert_equal 'Glendale', white.city
    assert_in_delta 34.15, white.latitude

    armenian = SchoolLanguage.find_by!(name: 'Armenian')
    assert_equal({ 2022 => 45, 2025 => 30 }, armenian.totals_by_year)
    assert_equal({ 2025 => 3 }, SchoolLanguage.find_by!(name: 'Filipino (Tagalog)').totals_by_year)

    points = armenian.map_points([2022, 2025])
    assert_equal [{ lng: -118.25, lat: 34.15, name: 'R. D. White Elementary', district: 'Glendale Unified', counts: [40, 30] }], points
  end

  test 're-running replaces the previous import' do
    write_year('elsch25.txt', [['19645000000001', 'Los Angeles', 'R. D. White Elementary', 'arm', 'Armenian', '30']])
    write_sites([])
    2.times { SchoolLanguages::Importer.import(@dir) }

    assert_equal 1, SchoolLanguageCount.count
    assert_equal 1, School.count
  end
end
