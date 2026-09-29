require 'test_helper'
require Rails.root.join('lib/religious_centers')
require Rails.root.join('lib/religious_centers/review_workbook')

class ReligiousCenters::ReviewWorkbookTest < ActiveSupport::TestCase
  test 'writes every change and flag, and reads back the reviewer decisions and notes' do
    rows = [{ 'row' => 2, 'NAME' => 'zz TEMPLE BETH AM', 'City' => 'Westminister', 'StreetAddress' => 'P.O. Box 1',
              'ReligiousGroup' => 'Judaism' }]
    result = ReligiousCenters::Cleaner.new(rows).run
    decisions = ReligiousCenters::ReviewWorkbook::Decisions.new(
      changes: { 'R2.name.caps' => 'Reject', 'R2.city.typo' => 'Westminster Village' },
      change_notes: { 'R2.name.caps' => 'Keep as written' },
      religions: { 'Judaism' => 'Accept' }, religion_notes: {},
      answers: { 'R2.street.po_box' => 'Fine without a map pin' }
    )

    Tempfile.create(['review', '.xlsx']) do |file|
      ReligiousCenters::ReviewWorkbook.new(result, decisions: decisions).write(file.path)
      read = ReligiousCenters::ReviewWorkbook.read_decisions(file.path)

      assert_equal result.changes.map(&:id).sort, read.changes.keys.sort
      assert_equal 'Reject', read.changes['R2.name.caps']
      assert_equal 'Westminster Village', read.changes['R2.city.typo']
      assert_equal 'Accept', read.changes['R2.name.zz']
      assert_equal 'Keep as written', read.change_notes['R2.name.caps']
      assert_equal 'Fine without a map pin', read.answers['R2.street.po_box']

      book = Roo::Excelx.new(file.path)
      assert_equal ['How to review', 'Summary', 'Changes', 'Religions', 'Needs your judgment', 'All centers'], book.sheets
    end
  end

  test 'missing workbook means no decisions yet' do
    assert_empty ReligiousCenters::ReviewWorkbook.read_decisions('/nonexistent.xlsx').changes
  end
end
