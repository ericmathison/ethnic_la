class EthnicChurchesController < ApplicationController
  before_action :authenticate_admin!, only: %i[new create edit update]

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

  def edit
    @ethnic_church = EthnicChurch.find(params[:id])
  end

  def update
    @ethnic_church = EthnicChurchBuilder.instantiate(
      ethnic_church: ethnic_church,
      languages: languages,
      country: country,
      religious_background: religious_background,
      address: address,
      note: note
    )

    if @ethnic_church.save
      redirect_to ethnic_church_path(@ethnic_church), notice: 'Successfully updated Ethnic Church'
    else
      flash.now.alert = @ethnic_church.errors.full_messages.join(', ')
      render 'new'
    end
  end

  private

  def ethnic_church
    ec = EthnicChurch.find_by(id: params[:id]) || EthnicChurch.new
    ec.assign_attributes(ethnic_church_params)
    ec
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
    addr = ethnic_church.address || ethnic_church.build_address(address_params)
    addr.assign_attributes(address_params)
    addr
  end

  def note
    n = ethnic_church.note || ethnic_church.build_note(note_params)
    n.assign_attributes(note_params)
    n
  end

  def note_params
    params.require(:ethnic_church).require(:note).permit(:content)
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
    params.require(:ethnic_church).require(:address).permit(:street, :city, :zip)
  end
end
