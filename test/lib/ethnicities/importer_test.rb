require 'test_helper'
require Rails.root.join('lib/ethnicities/importer')

class Ethnicities::ImporterTest < ActiveSupport::TestCase
  Importer = Ethnicities::Importer

  setup do
    @dir = Dir.mktmpdir
  end

  teardown do
    FileUtils.remove_entry(@dir)
  end

  test 'shows the "alone or in any combination" version of race groups and Hispanic groups as they are' do
    assert_equal 'Armenian', Importer.name('1117', 'Armenian alone or in any combination')
    assert_nil Importer.name('1006', 'Armenian alone')
    assert_equal 'Salvadoran', Importer.name('4022', 'Salvadoran')
    assert_equal 'Chinese', Importer.name('3822', 'Chinese, except Taiwanese alone or in any combination')
  end

  test 'leaves out umbrella and unspecified groups' do
    assert_nil Importer.name('1113', 'European alone or in any combination')
    assert_nil Importer.name('4016', 'Central American')
    assert_nil Importer.name('1222', 'Other White, not specified alone or in any combination')
    assert_nil Importer.name('3676', 'Mexican Indian (all tribes) alone or in any combination')
  end

  test 'groups by region of origin' do
    assert_equal 'Europe', Importer.category('1142')
    assert_equal 'Middle East & North Africa', Importer.category('1117')
    assert_equal 'Asia', Importer.category('3861')
    assert_equal 'Indigenous Americas', Importer.category('3715')
    assert_equal 'Latin America', Importer.category('4022')
    assert_equal 'United States & Canada', Importer.category('1292')
  end

  test 'imports LA-area counties and tracts, skipping groups below the reporting threshold' do
    File.write(File.join(@dir, 'popgroups.json'), { values: { item: {
      '1117' => 'Armenian alone or in any combination', '1006' => 'Armenian alone', '4022' => 'Salvadoran',
      '1113' => 'European alone or in any combination', '3715' => 'Zapotec alone or in any combination'
    } } }.to_json)
    File.write(File.join(@dir, '2020_gaz_tracts_06.txt'), <<~GAZETTEER)
      USPS\tGEOID\tALAND\tAWATER\tALAND_SQMI\tAWATER_SQMI\tINTPTLAT\tINTPTLONG
      CA\t06037301100\t1\t0\t1\t0\t34.15\t-118.25
      CA\t06059001101\t1\t0\t1\t0\t33.75\t-117.87
      CA\t06001400100\t1\t0\t1\t0\t37.87\t-122.23
    GAZETTEER
    rows = [
      'REGION_TYPE,REGION_ID,GEOID,ST,ITERID,COUNT,ANN',
      'COUNTY,1,0500000US06037,06,1117,230000,', 'COUNTY,1,0500000US06059,06,1117,10000,',
      'COUNTY,1,0500000US06001,06,1117,5000,', 'COUNTY,1,0500000US06037,06,1006,200000,',
      'COUNTY,1,0500000US06037,06,4022,400000,', 'COUNTY,1,0500000US06037,06,1113,900000,',
      'COUNTY,1,0500000US06037,06,3715,3800,',
      'TRACT,1,1400000US06037301100,06,1117,3000,', 'TRACT,1,1400000US06059001101,06,1117,40,',
      'TRACT,1,1400000US06001400100,06,1117,90,', 'TRACT,1,1400000US06037301100,06,4022,-888888888,X',
      'TRACT,1,1400000US06037301100,06,1113,5000,'
    ]
    File.write(File.join(@dir, 'ddhca_t01001.csv'), rows.join("\n") + "\n")
    system('zip', '-qj', File.join(@dir, '2020-ddhc-a.zip'), File.join(@dir, 'ddhca_t01001.csv'), exception: true)

    result = Importer.import(@dir)

    assert_equal 2, result.tracts
    assert_equal ['Armenian'], Ethnicity.pluck(:name), 'only groups with a reported tract can be mapped'
    armenian = Ethnicity.find_by!(slug: 'armenian')
    assert_equal 240_000, armenian.people
    assert_equal({ 'Los Angeles' => 230_000, 'Orange' => 10_000 }, armenian.people_by_county)
    assert_equal [40, 3000], armenian.ethnicity_counts.pluck(:people).sort
    assert_equal 'Census tract 3011, Los Angeles County', armenian.map_points.find { _1[:counts] == [3000] }.values_at(:name, :district).join(', ')
  end
end
