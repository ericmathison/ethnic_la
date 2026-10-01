require 'test_helper'
require Rails.root.join('lib/school_languages/language_names')

class SchoolLanguages::LanguageNamesTest < ActiveSupport::TestCase
  test 'old CDE codes and new ISO codes map to the same language' do
    assert_equal 'Spanish', SchoolLanguages::LanguageNames.for('01', 'Spanish')
    assert_equal 'Spanish', SchoolLanguages::LanguageNames.for('spa', 'Spanish; Castilian')
    assert_equal 'Filipino (Tagalog)', SchoolLanguages::LanguageNames.for('05', 'Filipino (Pilipino or Tagalog)')
    %w[phi fil tgl].each { assert_equal 'Filipino (Tagalog)', SchoolLanguages::LanguageNames.for(_1, 'Tagalog') }
    assert_equal 'Mandarin', SchoolLanguages::LanguageNames.for('cmn', 'Mandarin Chinese (Putonghua, Guoyu)')
  end

  test 'ISO codes without an override use the label before any alternate names' do
    assert_equal 'Chichewa', SchoolLanguages::LanguageNames.for('nya', 'Chichewa; Chewa; Nyanja')
    assert_equal 'Georgian', SchoolLanguages::LanguageNames.for('geo', 'Georgian')
  end

  test 'other and undetermined languages are not mapped' do
    %w[99 mis und mul].each { assert_nil SchoolLanguages::LanguageNames.for(_1, 'Other') }
  end

  test 'unknown CDE codes raise instead of being dropped' do
    assert_raises(ArgumentError) { SchoolLanguages::LanguageNames.for('C1', 'New language') }
  end
end
