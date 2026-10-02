class SchoolLanguage < ApplicationRecord
  has_many :school_language_counts, dependent: :delete_all

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation { self.slug = name.parameterize if slug.blank? && name.present? }

  def self.years
    SchoolLanguageCount.distinct.order(:year).pluck(:year)
  end

  # "2025-26" for 2025
  def self.school_year(year)
    "#{year}-#{format('%02d', (year + 1) % 100)}"
  end

  # [[language, total English learners in year]], alphabetically. Includes
  # languages with none that year, so every language can be picked.
  def self.with_totals(year)
    totals = SchoolLanguageCount.where(year: year).group(:school_language_id).sum(:english_learners)
    order(:name).map { [_1, totals.fetch(_1.id, 0)] }
  end

  def to_param
    slug
  end

  def totals_by_year
    school_language_counts.group(:year).order(:year).sum(:english_learners)
  end

  # One point per mapped school with its English learner count for each year:
  # { lng:, lat:, name:, district:, counts: [count for years[0], ...] }
  def map_points(years)
    counts = school_language_counts.joins(:school).where.not(schools: { latitude: nil })
                                   .pluck(:school_id, :year, :english_learners)
    schools = School.where(id: counts.map(&:first).uniq).index_by(&:id)

    counts.group_by(&:first).map do |school_id, rows|
      school = schools.fetch(school_id)
      by_year = rows.to_h { |_, year, count| [year, count] }
      { lng: school.longitude.round(5), lat: school.latitude.round(5), name: school.name, district: school.district,
        counts: years.map { by_year.fetch(_1, 0) } }
    end
  end
end
