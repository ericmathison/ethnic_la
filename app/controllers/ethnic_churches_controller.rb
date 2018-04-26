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
    @ethnic_church = EthnicChurchBuilder.instantiate(
      ethnic_church: ethnic_church,
      languages: languages,
      country: country,
      religious_background: religious_background,
      address: address,
      note: note
    )

    if @ethnic_church.save
      redirect_to ethnic_church_path(@ethnic_church), notice: 'Successfully added new Ethnic Church'
    else
      flash.now.alert = @ethnic_church.errors.full_messages.join(', ')
      render 'new'
    end
  end

  private

  def ethnic_church
    EthnicChurch.new(ethnic_church_params)
  end

  def languages
    params[:ethnic_church][:language][:name].reject(&:blank?).map do |lang_name|
      Language.find_or_initialize_by(name: lang_name)
    end
  end

  def country
    country = params[:ethnic_church][:country][:name]
    Country.find_or_initialize_by(name: country)
  end

  def address
    Address.new(address_params)
  end

  def note
    Note.new(note_params)
  end

  def note_params
    params.require(:note).permit(:content)
  end

  def religious_background
    persuasion = params[:ethnic_church][:religious_background][:persuasion]
    ReligiousBackground.find_or_initialize_by(persuasion: persuasion)
  end

  def ethnic_church_params
    params.require(:ethnic_church)
      .permit(:name, :phone, :website, :pastors_name, :email)
      .transform_values { |val| val if val.present? }
  end

  def address_params
    params.require(:address).permit(:street, :city, :zip)
  end
end
