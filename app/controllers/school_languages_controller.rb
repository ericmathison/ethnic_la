class SchoolLanguagesController < ApplicationController
  DEFAULT_LANGUAGE = 'arabic'.freeze

  def index
    redirect_to school_language_path(params[:language].presence || DEFAULT_LANGUAGE, year: params[:year].presence)
  end

  def show
    @years = SchoolLanguage.years
    @year = params[:year].to_i.in?(@years) ? params[:year].to_i : @years.last
    @language = SchoolLanguage.find_by!(slug: params[:id])
    @languages = SchoolLanguage.with_totals(@years.last)
    @totals = @language.totals_by_year
  end
end
