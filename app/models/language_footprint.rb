# Where a language's English learners go to school, for the language map's cards
class LanguageFootprint < Footprint
  attr_reader :language, :endonym, :lang, :year, :english_learners, :dots

  def self.endonyms
    @endonyms ||= YAML.load_file(Rails.root.join('config/school_language_endonyms.yml'))
  end

  # One footprint per language, from its most recent year with English learners
  def self.all
    latest = SchoolLanguageCount.group(:school_language_id).maximum(:year)
    rows = SchoolLanguageCount.joins(:school)
                              .where(latest.map { |id, year| "(school_language_id = #{id.to_i} AND year = #{year.to_i})" }.join(' OR ').presence || 'FALSE')
                              .pluck(:school_language_id, :english_learners, 'schools.latitude', 'schools.longitude')
                              .group_by(&:first)

    SchoolLanguage.order(:name).filter_map do |language|
      next unless latest[language.id]

      new(language, latest[language.id], rows.fetch(language.id, []).map { _1.drop(1) })
    end
  end

  def initialize(language, year, counts)
    @language = language
    @year = year
    @english_learners = counts.sum(&:first)
    @dots = self.class.dots_for(counts)
    details = self.class.endonyms.fetch(language.name, {})
    @endonym = details['endonym']
    @lang = details['lang']
  end
end
