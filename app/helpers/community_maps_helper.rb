# Cards for the shared footprint wall (shared/_footprint_wall) on the language
# and ethnicity maps, largest first
module CommunityMapsHelper
  def language_cards
    latest_year = SchoolLanguage.years.last
    LanguageFootprint.all.sort_by { [-_1.english_learners, _1.language.name] }.map do |footprint|
      language = footprint.language
      { href: school_language_path(language), slug: language.slug, name: language.name,
        endonym: footprint.endonym, lang: footprint.lang, size: footprint.english_learners,
        title: "#{language.name}: #{number_with_delimiter(footprint.english_learners)} English learners",
        note: ("Last reported #{SchoolLanguage.school_year(footprint.year)}" unless footprint.year == latest_year),
        dots: footprint.dots }
    end
  end

  def ethnicity_cards
    EthnicityFootprint.all.sort_by { [-_1.ethnicity.people, _1.ethnicity.name] }.map do |footprint|
      ethnicity = footprint.ethnicity
      { href: ethnicity_path(ethnicity), slug: ethnicity.slug, name: ethnicity.name, size: ethnicity.people,
        title: "#{ethnicity.name}: #{number_with_delimiter(ethnicity.people)} people", category: ethnicity.category,
        dots: footprint.dots }
    end
  end
end
