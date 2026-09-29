require 'caxlsx'
require 'roo'

module ReligiousCenters
  # Writes the cleanup review workbook and reads the reviewer's decisions back.
  class ReviewWorkbook
    CHANGE_HEADERS = ['ID', 'Row', 'Center', 'Kind', 'Field', 'Before', 'After', 'Why', 'Confidence', 'Decision', 'Your notes'].freeze

    # Groups changes by the rule that produced them (the end of the change ID).
    KINDS = [
      [/\.squish\z/, 'Spacing / Excel artifacts'], [/\.name\.zz\z/, 'ZZ code'], [/\.name\.uncertain\z/, '?? marker'],
      [/\.name\.caps\z/, 'ALL CAPS name'], [/\.name\.punctuation\z/, 'Name punctuation'], [/\.street\./, 'Street'],
      [/\.city\./, 'City'], [/\.zip\.geocode\z/, 'ZIP from map lookup'], [/\.zip\./, 'ZIP'], [/\.phone\./, 'Phone format'],
      [/\.community\./, 'Community / tradition'], [/\.email\./, 'Emails / websites'], [/\.extra\./, 'Column1'],
      [/\.notes\./, 'Contact info in notes'], [/\.status\./, 'Unverified status'], [/\.manual\./, 'Hand correction']
    ].freeze

    def self.kind(change_id)
      KINDS.find { |pattern, _| change_id.match?(pattern) }&.last || 'Other'
    end
    RELIGION_HEADERS = ['Source label', 'Centers', 'Maps to', 'Why', 'Confidence', 'Decision', 'Your notes'].freeze
    FLAG_HEADERS = ['ID', 'Row', 'Center', 'Issue', 'Details', 'Suggestion', 'Your answer'].freeze
    CENTER_HEADERS = ['Row', 'Name', 'Religions', 'Status', 'Name uncertain', 'Street', 'City', 'ZIP', 'Phone', 'Website',
                      'Community / tradition', 'Leader (admin-only)', 'Email (admin-only)', 'Notes (admin-only)', 'Map match'].freeze

    Decisions = Struct.new(:changes, :change_notes, :religions, :religion_notes, :answers, keyword_init: true) do
      def self.empty = new(changes: {}, change_notes: {}, religions: {}, religion_notes: {}, answers: {})
    end

    def self.read_decisions(path)
      return Decisions.empty unless path && File.exist?(path)

      book = Roo::Excelx.new(path)
      changes = column_pairs(book, 'Changes', key: 'ID', values: ['Decision', 'Your notes'])
      religions = column_pairs(book, 'Religions', key: 'Source label', values: ['Decision', 'Your notes'])
      answers = column_pairs(book, 'Needs your judgment', key: 'ID', values: ['Your answer'])
      Decisions.new(changes: changes.transform_values(&:first), change_notes: changes.transform_values(&:last),
                    religions: religions.transform_values(&:first), religion_notes: religions.transform_values(&:last),
                    answers: answers.transform_values(&:first))
    end

    def self.column_pairs(book, sheet, key:, values:)
      return {} unless book.sheets.include?(sheet)

      book.default_sheet = sheet
      headers = book.row(1)
      key_index = headers.index(key)
      value_indexes = values.map { |name| headers.index(name) }
      (2..book.last_row.to_i).to_h do |line|
        cells = book.row(line)
        [cells[key_index].to_s, value_indexes.map { |i| cells[i].to_s.strip.presence }]
      end.except('')
    end

    def initialize(result, decisions: Decisions.empty)
      @result = result
      @decisions = decisions
    end

    def write(path)
      package = Axlsx::Package.new
      package.use_shared_strings = true
      book = package.workbook
      @styles = build_styles(book.styles)

      instructions_sheet(book)
      summary_sheet(book)
      changes_sheet(book)
      religions_sheet(book)
      flags_sheet(book)
      centers_sheet(book)
      package.serialize(path)
    end

    private

    def build_styles(styles)
      base = { font_name: 'Arial', sz: 10, alignment: { vertical: :top, wrap_text: true } }
      {
        title: styles.add_style(font_name: 'Arial', sz: 14, b: true),
        text: styles.add_style(**base),
        bold: styles.add_style(**base, b: true),
        header: styles.add_style(**base, b: true, bg_color: '49473F', fg_color: 'FFFFFF'),
        private_header: styles.add_style(**base, b: true, bg_color: '8B2E2E', fg_color: 'FFFFFF'),
        input: styles.add_style(**base, bg_color: 'FFF2A8', border: { style: :thin, color: 'C9B458' }),
        low: styles.add_style(**base, bg_color: 'F8D7D3'),
        medium: styles.add_style(**base, bg_color: 'FCE9C8'),
        high: styles.add_style(**base)
      }
    end

    def instructions_sheet(book)
      book.add_worksheet(name: 'How to review') do |sheet|
        sheet.add_row ['Religious centers cleanup review'], style: @styles[:title]
        [
          ['What this is', 'Every edit the cleanup proposes to "Religious Groups.xlsx". Your original spreadsheet is never changed; nothing reaches the website until you are happy with this review.'],
          ['Yellow cells', 'The only cells you need to edit.'],
          ['Changes sheet', 'One row per proposed edit. In "Decision" keep Accept, change it to Reject, or type the value you want instead. Use the filter arrows to work through one kind of change at a time.'],
          ['Confidence', 'high = mechanical fix (spacing, capitalization, obvious typo). medium = a judgment call. low = a guess; please look at these (shaded pink).'],
          ['Religions sheet', 'How each religion label in the spreadsheet is grouped. Decision: Accept, Reject (sends those centers to the admin-only Other page), or type the religions separated by commas.'],
          ['Needs your judgment', "Things the cleanup won't guess at. Write an answer in \"Your answer\" and Claude will apply it."],
          ['All centers', 'Preview of every center after the changes above, including map lookup results. Red headers are admin-only fields.'],
          ['"ZZ" names', 'Listed in a source but not found when checked in person. The ZZ is removed from the name and the center is marked "Listed but not found in person" (admin-only).'],
          ['"??" names', 'The ?? is removed from the name and the center is marked "name uncertain" (visible to admins only).'],
          ['Unverified', 'Suggested when notes say house, empty field, moved, closed, etc. Unverified centers are shown to admins only.'],
          ['Admin-only fields', 'Leader, email, notes, "name uncertain", and the status of unverified/not-found centers are only shown to logged-in admins.'],
          ['When you are done', 'Save this file and tell Claude. Re-running the cleanup keeps every decision and note you entered.']
        ].each { |label, text| sheet.add_row [label, text], style: [@styles[:bold], @styles[:text]] }
        sheet.column_widths 22, 110
      end
    end

    def summary_sheet(book)
      book.add_worksheet(name: 'Summary') do |sheet|
        sheet.add_row ['Summary (updates as you edit decisions)'], style: @styles[:title]
        sheet.add_row ['Proposed changes', 'Count'], style: @styles[:header]
        formula_rows(sheet, [
          ['All', '=COUNTA(Changes!A:A)-1'],
          ['High confidence', '=COUNTIF(Changes!I:I,"high")'],
          ['Medium confidence', '=COUNTIF(Changes!I:I,"medium")'],
          ['Low confidence (please look at these)', '=COUNTIF(Changes!I:I,"low")'],
          ['Rejected by you', '=COUNTIF(Changes!J:J,"Reject")'],
          ['Changed to your own value', '=COUNTA(Changes!J:J)-1-COUNTIF(Changes!J:J,"Accept")-COUNTIF(Changes!J:J,"Reject")']
        ])
        sheet.add_row []
        sheet.add_row ['Kinds of change', 'Count'], style: @styles[:header]
        kinds = @result.changes.map { |change| self.class.kind(change.id) }.tally.sort_by { -_2 }.map(&:first)
        formula_rows(sheet, kinds.map { |kind| [kind, %(=COUNTIF(Changes!D:D,"#{kind}"))] })
        sheet.add_row []
        sheet.add_row ['Centers', 'Count'], style: @styles[:header]
        formula_rows(sheet, [
          ['All centers', "=COUNTA('All centers'!A:A)-1"],
          ['Verified (public)', %(=COUNTIF('All centers'!D:D,"Verified"))],
          ['Unverified (admin-only)', %(=COUNTIF('All centers'!D:D,"Unverified"))],
          ['Listed but not found in person (admin-only)', %(=COUNTIF('All centers'!D:D,"Listed but not found in person"))],
          ['Name uncertain', %(=COUNTIF('All centers'!E:E,"Yes"))],
          ['On the map', %(=COUNTIF('All centers'!O:O,"Exact")+COUNTIF('All centers'!O:O,"Approximate"))],
          ['Needs your judgment', "=COUNTA('Needs your judgment'!A:A)-1"]
        ])
        sheet.column_widths 50, 12
      end
    end

    # caxlsx escapes values starting with "=" by default; these are our own formulas.
    def formula_rows(sheet, rows)
      rows.each { |row| sheet.add_row row, style: @styles[:text], escape_formulas: false }
    end

    def changes_sheet(book)
      book.add_worksheet(name: 'Changes') do |sheet|
        sheet.add_row CHANGE_HEADERS, style: @styles[:header]
        @result.changes.each do |change|
          decision = @decisions.changes[change.id] || Cleaner::ACCEPT
          style = @styles.fetch(change.confidence.to_sym)
          sheet.add_row [change.id, change.row, change.center, self.class.kind(change.id), change.field, change.before, change.after,
                         change.rule, change.confidence, decision, @decisions.change_notes[change.id]],
                        style: [style] * 9 + [@styles[:input], @styles[:input]], types: [:string, :integer] + [:string] * 9
        end
        finish_table(sheet, CHANGE_HEADERS.size, @result.changes.size, [14, 6, 34, 20, 14, 34, 34, 40, 11, 14, 24], decision_column: 'J')
      end
    end

    def religions_sheet(book)
      book.add_worksheet(name: 'Religions') do |sheet|
        sheet.add_row RELIGION_HEADERS, style: @styles[:header]
        @result.religion_mappings.sort_by { |_, m| -m[:count] }.each do |label, entry|
          mapping = entry[:mapping]
          sheet.add_row [label, entry[:count], mapping.religions.join(', '), mapping.reason, mapping.confidence,
                         @decisions.religions[label] || Cleaner::ACCEPT, @decisions.religion_notes[label]],
                        style: [@styles.fetch(mapping.confidence.to_sym)] * 5 + [@styles[:input], @styles[:input]],
                        types: [:string, :integer] + [:string] * 5
        end
        finish_table(sheet, RELIGION_HEADERS.size, @result.religion_mappings.size, [30, 9, 26, 60, 11, 22, 24], decision_column: 'F')
      end
    end

    def flags_sheet(book)
      book.add_worksheet(name: 'Needs your judgment') do |sheet|
        sheet.add_row FLAG_HEADERS, style: @styles[:header]
        @result.flags.sort_by { |flag| [flag.issue, flag.row] }.each do |flag|
          sheet.add_row [flag.id, flag.row, flag.center, flag.issue, flag.details, flag.suggestion, @decisions.answers[flag.id]],
                        style: [@styles[:text]] * 6 + [@styles[:input]], types: [:string, :integer] + [:string] * 5
        end
        finish_table(sheet, FLAG_HEADERS.size, @result.flags.size, [18, 6, 34, 30, 44, 34, 34])
      end
    end

    def centers_sheet(book)
      book.add_worksheet(name: 'All centers') do |sheet|
        styles = CENTER_HEADERS.map { |header| header.include?('admin-only') ? @styles[:private_header] : @styles[:header] }
        sheet.add_row CENTER_HEADERS, style: styles
        @result.records.each do |r|
          sheet.add_row [r[:row], r[:name], r[:religions].join(', '), ReligiousCenter::STATUSES.fetch(r[:status]),
                         r[:name_uncertain] ? 'Yes' : nil, r[:street], r[:city], r[:zip], r[:phone], r[:website], r[:community],
                         r[:leader], r[:email], r[:notes], r[:geocode_match]],
                        style: @styles[:text], types: [:integer] + [:string] * 14
        end
        finish_table(sheet, CENTER_HEADERS.size, @result.records.size, [6, 34, 16, 16, 9, 26, 16, 10, 16, 26, 22, 20, 24, 40, 11])
      end
    end

    def finish_table(sheet, columns, rows, widths, decision_column: nil)
      last_column = Axlsx.col_ref(columns - 1)
      sheet.auto_filter = "A1:#{last_column}#{rows + 1}"
      sheet.sheet_view.pane do |pane|
        pane.top_left_cell = 'A2'
        pane.state = :frozen_split
        pane.y_split = 1
        pane.active_pane = :bottom_left
      end
      sheet.column_widths(*widths)
      return unless decision_column && rows.positive?

      # Suggest Accept/Reject but allow typing a corrected value.
      sheet.add_data_validation("#{decision_column}2:#{decision_column}#{rows + 1}",
                                type: :list, formula1: '"Accept,Reject"', hideDropDown: false, showErrorMessage: false)
    end
  end
end
