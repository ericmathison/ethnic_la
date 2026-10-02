class EthnicitiesController < ApplicationController
  DEFAULT_ETHNICITY = 'armenian'.freeze

  def index
    redirect_to ethnicity_path(params[:ethnicity].presence || DEFAULT_ETHNICITY)
  end

  # Like the language map: cards for every group beside one big map. Picking a
  # card loads that group's JSON and swaps the map in place.
  def show
    @ethnicity = Ethnicity.find_by!(slug: params[:id])

    respond_to do |format|
      format.html
      format.json { render json: ethnicity_data }
    end
  end

  private

  # Shaped like the language map's data (one "year") so the same script draws both
  def ethnicity_data
    { name: @ethnicity.name, slug: @ethnicity.slug, count_label: "people who identify as #{@ethnicity.name}",
      years: [2020], totals: [@ethnicity.people], points: @ethnicity.map_points,
      table: @ethnicity.people_by_county.sort_by { -_2 }.map { |county, people| ["#{county} County", people] } }
  end
  helper_method :ethnicity_data
end
