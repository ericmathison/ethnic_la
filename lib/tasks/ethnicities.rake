namespace :ethnicities do
  desc 'Import 2020 Census detailed ethnic groups for the LA area (DIR=data/ethnicities)'
  task import: :environment do
    require Rails.root.join('lib/ethnicities/importer')

    result = Ethnicities::Importer.import(ENV.fetch('DIR', Rails.root.join('data/ethnicities').to_s))
    puts "Imported #{result.counts} counts for #{result.ethnicities} groups in #{result.tracts} census tracts"
  end
end
