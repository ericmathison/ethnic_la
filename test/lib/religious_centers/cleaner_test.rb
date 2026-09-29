require 'test_helper'
require Rails.root.join('lib/religious_centers')

class ReligiousCenters::CleanerTest < ActiveSupport::TestCase
  def row(overrides = {})
    { 'row' => 2, 'NAME' => 'Sample Temple', 'StreetAddress' => '1 Main St', 'City' => 'Los Angeles', 'ZIP' => 90012.0,
      'Phone' => '213-555-0100', 'Column1' => nil, 'ReligiousGroup' => 'Buddhism', 'Leader' => nil, 'Emails' => nil,
      'Notes2' => nil }.merge(overrides)
  end

  def clean(rows, **options)
    ReligiousCenters::Cleaner.new(rows.is_a?(Hash) ? [rows] : rows, **options).run
  end

  def record(overrides = {}, options = {})
    clean(row(overrides), **options).records.first
  end

  test 'ZZ prefix marks a center as listed but not found' do
    result = clean(row('NAME' => 'zz Sample Temple'))

    assert_equal 'Sample Temple', result.records.first[:name]
    assert_equal 'not_found', result.records.first[:status]
    assert_equal 'high', result.changes.find { _1.id == 'R2.name.zz' }.confidence
  end

  test '?? marker is removed and the name flagged uncertain' do
    rec = record('NAME' => '??Sample Temple ??')

    assert_equal 'Sample Temple', rec[:name]
    assert rec[:name_uncertain]
  end

  test 'ALL CAPS names become title case, keeping acronyms and apostrophes' do
    assert_equal "Congregation B'nai Emet of L.A.", record('NAME' => "CONGREGATION B'NAI EMET OF L.A.")[:name]
    assert_equal 'JFC-Temple Ner Ami', record('NAME' => 'JFC-TEMPLE NER AMI')[:name]
  end

  test 'Excel line-break artifacts and extra spaces are cleaned' do
    rec = record('StreetAddress' => '424 S. Ramona Ave._x000B_ ', 'Phone' => '626-280-2852_x000B_')

    assert_equal '424 S. Ramona Ave', rec[:street]
    assert_equal '626-280-2852', rec[:phone]
  end

  test 'city cleanup strips state and ZIP, and fixes typos' do
    assert_equal 'Monterey Park', record('City' => 'Monterey Park, CA ')[:city]
    assert_equal 'Westminster', record('City' => 'Westminister')[:city]

    moved = record('City' => 'Malibu, Ca 90265', 'ZIP' => nil)
    assert_equal ['Malibu', '90265'], moved.values_at(:city, :zip)
  end

  test 'phone numbers are standardized; incomplete ones are flagged, not changed' do
    assert_equal '310-475-4985 / 310-555-1212', record('Phone' => '(310) 475-4985 or 310.555.1212')[:phone]

    result = clean(row('Phone' => '213-625-348'))
    assert_equal '213-625-348', result.records.first[:phone]
    assert_includes result.flags.map(&:issue), 'Phone number looks incomplete or mistyped'
  end

  test 'websites in the Emails column move to Website; emails stay private' do
    rec = record('Emails' => 'http://temple.org info@temple.org')

    assert_equal 'http://temple.org', rec[:website]
    assert_equal 'info@temple.org', rec[:email]
  end

  test 'Leader column becomes the community, with typos and country names fixed' do
    assert_equal 'Burmese', record('Leader' => 'Bermese')[:community]
    assert_equal 'Sri Lankan Theravada', record('Leader' => 'Sir Lanka Theravada ')[:community]

    uncertain = record('Leader' => 'Chinese ?')
    assert_nil uncertain[:community]
    assert_match 'Community (unconfirmed): Chinese ?', uncertain[:notes]
  end

  test 'notes describing a house suggest unverified, with lower confidence for real temples' do
    result = clean([row('Notes2' => 'It is just a house'), row('row' => 3, 'Notes2' => 'Temple in House')])

    assert_equal %w[unverified unverified], result.records.map { _1[:status] }
    assert_equal %w[medium low], result.changes.select { _1.id.end_with?('status.notes') }.map(&:confidence)
  end

  test 'rejected changes are skipped and custom values replace the proposal' do
    rec = record({ 'NAME' => 'TEMPLE BETH AM', 'City' => 'Westminister' },
                 { decisions: { 'R2.name.caps' => 'Reject', 'R2.city.typo' => 'Westminster Village' } })

    assert_equal 'TEMPLE BETH AM', rec[:name]
    assert_equal 'Westminster Village', rec[:city]
  end

  test 'religion labels map to canonical religions and reviewer overrides apply' do
    result = clean([row('ReligiousGroup' => 'Taoist/Buddhist'), row('row' => 3, 'ReligiousGroup' => 'Isalm'),
                    row('row' => 4, 'ReligiousGroup' => 'New age')])
    assert_equal [%w[Buddhism Taoism], ['Islam'], ['Other']], result.records.map { _1[:religions] }

    overridden = clean(row('ReligiousGroup' => 'Isalm'), religion_decisions: { 'Isalm' => 'Reject' })
    assert_equal ['Other'], overridden.records.first[:religions]
  end

  test 'religion branches are added to the community' do
    assert_equal 'Shia', record('ReligiousGroup' => 'Islam-Shia')[:community]
  end

  test 'manual suggestions propose changes and flags' do
    manual = [{ 'row' => 2, 'reason' => 'Typo', 'confidence' => 'high', 'sets' => { 'name' => 'Fixed Temple' } },
              { 'row' => 2, 'flag' => 'Check this', 'details' => 'Details', 'suggestion' => 'Look' }]
    result = clean(row, manual: manual)

    assert_equal 'Fixed Temple', result.records.first[:name]
    assert_includes result.flags.map(&:issue), 'Check this'
  end

  test 'P.O. boxes and duplicates are flagged' do
    result = clean([row('StreetAddress' => 'P.O. Box 12'), row('row' => 3, 'StreetAddress' => 'P.O. Box 12')])

    issues = result.flags.map(&:issue)
    assert_includes issues, 'Mailing address only (P.O. box)'
    assert_includes issues, 'Possible duplicate'
  end

  test 'geocoding sets coordinates, fills missing ZIPs, and rejects distant matches' do
    geocoder = Object.new
    def geocoder.geocode(addresses)
      addresses.transform_values do |address|
        zip = address[:street].start_with?('9') ? '92335' : '90012'
        ReligiousCenters::CensusGeocoder::Result.new(match: 'Match', exact: true, matched_address: "X, LOS ANGELES, CA, #{zip}",
                                                     latitude: 34.0, longitude: -118.0)
      end
    end

    result = clean([row('ZIP' => nil), row('row' => 3, 'StreetAddress' => '9 Far St', 'ZIP' => 91335.0)], geocoder: geocoder)
    near, far = result.records

    assert_equal ['90012', 34.0, 'Exact'], near.values_at(:zip, :latitude, :geocode_match)
    assert_nil far[:latitude]
    assert_equal 'Conflicting', far[:geocode_match]
  end
end
