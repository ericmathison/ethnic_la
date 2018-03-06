class EthnicChurchesController < ApplicationController
  def index
    @ethnic_churches = EthnicChurch.all
    @languages = Language.list
  end

  def show
    @ethnic_church = EthnicChurch.find(params[:id])
  end
end
