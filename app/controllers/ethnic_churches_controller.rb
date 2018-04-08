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
    @ethnic_church = EthnicChurch.new(ethnic_church_params)
    languages = params[:language][:name]
    @ethnic_church.languages = languages
    @ethnic_church.country = Country.find_or_initialize_by(name: country_params[:name])
    @ethnic_church.religious_background = ReligiousBackground.find_or_initialize_by(persuasion: religious_background_params[:persuasion])
    @ethnic_church.build_address(address_params)
    @ethnic_church.build_note(note_params)

    if @ethnic_church.save
      redirect_to ethnic_church_path(@ethnic_church), notice: 'Successfully added new Ethnic Church'
    else
      flash.now.alert = @ethnic_church.errors.full_messages.join(', ')
      render 'new'
    end
  end

  private

  def ethnic_church_params
    params.require(:ethnic_church).permit(:name, :phone, :website, :pastors_name, :email)
  end

  def language_params
    params.require(:language).permit(:name)
  end

  def country_params
    params.require(:country).permit(:name)
  end

  def religious_background_params
    params.require(:religious_background).permit(:persuasion)
  end

  def note_params
    params.require(:note).permit(:content)
  end

  def address_params
    params.require(:address).permit(:street, :city, :zip)
  end
end
