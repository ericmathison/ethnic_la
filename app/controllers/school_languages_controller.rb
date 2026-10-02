class SchoolLanguagesController < ApplicationController
  DEFAULT_LANGUAGE = 'arabic'.freeze

  def index
    redirect_to school_language_path(params[:language].presence || DEFAULT_LANGUAGE, year: params[:year].presence)
  end

  # The page lists every language as a card beside one big map. Picking a
  # card loads that language's JSON and swaps the map in place.
  def show
    @years = SchoolLanguage.years
    @year = params[:year].to_i.in?(@years) ? params[:year].to_i : @years.last
    @language = SchoolLanguage.find_by!(slug: params[:id])

    respond_to do |format|
      format.html
      format.json { render json: language_data }
    end
  end

  private

  def language_data
    details = LanguageFootprint.endonyms.fetch(@language.name, {})
    totals = @language.totals_by_year
    { name: @language.name, slug: @language.slug, endonym: details['endonym'], lang: details['lang'],
      years: @years, totals: @years.map { totals.fetch(_1, 0) }, points: @language.map_points(@years) }
  end
  helper_method :language_data
end
