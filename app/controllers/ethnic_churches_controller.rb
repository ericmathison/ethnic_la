class EthnicChurchesController < ApplicationController
  def index
    @ethnic_churches = EthnicChurch.page(params[:page])
    @languages = Language.list
  end

  def show
    @ethnic_church = EthnicChurch.find(params[:id])
  end

  def new
    @ethnic_church = EthnicChurch.new
  end

  def create
    @ethnic_church = EthnicChurchBuilder.instantiate(params)

    if @ethnic_church.save
      redirect_to ethnic_church_path(@ethnic_church), notice: 'Successfully added new Ethnic Church'
    else
      flash.now.alert = @ethnic_church.errors.full_messages.join(', ')
      render 'new'
    end
  end
end
