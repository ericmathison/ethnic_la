namespace :school_languages do
  desc 'Import CDE English learner language counts for the LA area (DIR=data/school_languages)'
  task import: :environment do
    require Rails.root.join('lib/school_languages/importer')

    result = SchoolLanguages::Importer.import(ENV.fetch('DIR', Rails.root.join('data/school_languages').to_s))
    puts "Imported #{result.counts} counts for #{result.languages} languages at #{result.schools} schools " \
         "(#{result.years.first}-#{result.years.last})"
    puts "#{result.unmapped_schools} schools have no location and won't be mapped" if result.unmapped_schools.positive?
  end
end
