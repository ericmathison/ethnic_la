class EthnicChurchesController < ApplicationController
  def index
    @ethnic_churches = EthnicChurch.all
    @languages = Language.list
  end

  def show
    @ethnic_church = EthnicChurch.find(params[:id])
  end

  def new
    @ethnic_church = EthnicChurch.new
    @language_array = Language.pluck(:name).reject(&:nil?).sort.map { |lang| [lang, lang] }
  end

  def create
    ec = EthnicChurch.new(ethnic_church_params)

    lang = Language.find_by(name: language_params[:name])

    if lang
      ec.languages = [lang]
    else
      ec.languages.build(name: language_params[:name])
    end

    ec.country = Country.find_or_initialize_by(name: country_params[:name])
    ec.religious_background = ReligiousBackground.find_or_initialize_by(persuasion: religious_background_params[:persuasion])
    ec.build_address(address_params)
    if ec.save
      redirect_to ethnic_church_path(ec), notice: 'Successfully added new Ethnic Church'
    else
      render 'new', flash[:error] = 'Error adding new ethnic church'
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

  def address_params
    params.require(:address).permit(:street, :city, :zip)
  end
end
