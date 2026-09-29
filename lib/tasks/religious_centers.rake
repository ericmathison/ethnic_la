namespace :religious_centers do
  desc 'Clean the religious centers spreadsheet, geocode it, and write the review workbook (SOURCE=, REVIEW=)'
  task review: :environment do
    require Rails.root.join('lib/religious_centers')
    require Rails.root.join('lib/religious_centers/review_workbook')

    data = Rails.root.join('data')
    source = ENV.fetch('SOURCE', File.expand_path('~/Desktop/Religious Groups.xlsx'))
    review = ENV.fetch('REVIEW', File.expand_path('~/Desktop/Religious Groups - Cleanup Review.xlsx'))
    manual = data.join('manual_suggestions.yml')

    sheet = Roo::Excelx.new(source).sheet(0)
    headers = sheet.row(1)
    rows = (2..sheet.last_row).filter_map do |line|
      values = sheet.row(line)
      { 'row' => line }.merge(headers.compact.zip(values).to_h) if values.compact.any? { _1.to_s.strip.present? }
    end

    decisions = ReligiousCenters::ReviewWorkbook.read_decisions(review)
    if File.exist?(review)
      FileUtils.mkdir_p(data.join('review_backups'))
      FileUtils.cp(review, data.join('review_backups', "#{Time.current.strftime('%Y%m%d-%H%M%S')}.xlsx"))
    end

    result = ReligiousCenters::Cleaner.new(
      rows,
      decisions: decisions.changes,
      religion_decisions: decisions.religions,
      manual: File.exist?(manual) ? YAML.load_file(manual) : [],
      geocoder: ReligiousCenters::CensusGeocoder.new(cache_path: data.join('geocode_cache.json').to_s)
    ).run

    ReligiousCenters::ReviewWorkbook.new(result, decisions: decisions).write(review)
    File.write(data.join('religious_centers.json'), JSON.pretty_generate(result.records))

    puts "#{result.records.size} centers, #{result.changes.size} proposed changes, #{result.flags.size} items need judgment"
    puts "Review workbook: #{review}"
  end

  desc 'Import the reviewed religious centers (FILE=data/religious_centers.json)'
  task import: :environment do
    require Rails.root.join('lib/religious_centers')
    require Rails.root.join('lib/religious_centers/importer')

    counts = ReligiousCenters::Importer.import(ENV.fetch('FILE', Rails.root.join('data/religious_centers.json').to_s))
    puts "Imported #{counts[:centers]} centers in #{counts[:religions]} religions"
  end
end
