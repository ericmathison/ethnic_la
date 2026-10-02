class SchoolLanguagesController < ApplicationController
  DEFAULT_LANGUAGE = 'arabic'.freeze
  # Languages with fewer English learners than this are under "smaller languages" on the browse page
  BROWSE_MINIMUM = 20

  def index
    redirect_to school_language_path(params[:language].presence || DEFAULT_LANGUAGE, year: params[:year].presence)
  end

  # Every language as a card with a small dot map of where its speakers are
  def browse
    @latest_year = SchoolLanguage.years.last
  end

  def show
    @years = SchoolLanguage.years
    @year = params[:year].to_i.in?(@years) ? params[:year].to_i : @years.last
    @language = SchoolLanguage.find_by!(slug: params[:id])
    @languages = SchoolLanguage.with_totals(@years.last)
    @totals = @language.totals_by_year
  end
end
