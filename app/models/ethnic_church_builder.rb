class EthnicChurchBuilder
  class << self
    def instantiate(params)
      @params = params

      @ec = EthnicChurch.new(ethnic_church_params)

      @ec.languages = languages
      @ec.country = country
      @ec.religious_background = religious_background
      @ec.build_address(address_params)
      @ec.build_note(note_params)

      @ec
    end

    private

    def languages
      @params[:language][:name].reject(&:blank?).map do |lang_name|
        Language.find_or_initialize_by(name: lang_name)
      end
    end

    def country
      country = @params[:country][:name]
      Country.find_or_initialize_by(name: country)
    end

    def religious_background
      persuasion = @params[:religious_background][:persuasion]
      ReligiousBackground.find_or_initialize_by(persuasion: persuasion)
    end

    def ethnic_church_params
      @params.require(:ethnic_church)
        .permit(:name, :phone, :website, :pastors_name, :email)
        .transform_values { |val| val if val.present? }
    end

    def note_params
      @params.require(:note).permit(:content)
    end

    def address_params
      @params.require(:address).permit(:street, :city, :zip)
    end
  end
end
