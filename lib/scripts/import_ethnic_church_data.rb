require 'csv'

headers = [:street, :city, :country, :website, :language, :name, :notes, :pastors_name, :phone, :religious_background, :state, :zip]

CSV.foreach(ARGV[0], headers: headers) do |csv|
  hash = csv.to_h.transform_values(&:strip).transform_values do |value|
    if value.present?
      value
    else
      nil
    end
  end

  ethnic_church = hash.slice(:name, :phone, :website, :pastors_name)
  language = hash.slice(:language)
  country = hash.slice(:country)
  religious_background = hash.slice(:religious_background)
  notes = hash.slice(:notes)
  address = hash.slice(:street, :city, :state, :zip)

  EthnicChurch.transaction do
    language = Language.find_or_initialize_by({name: language[:language]})
    country = Country.find_or_initialize_by({name: country[:country]})
    religious_background = ReligiousBackground.find_or_initialize_by({persuasion: religious_background[:religious_background]})

    ethnic_church = EthnicChurch.new(ethnic_church)
    ethnic_church.language = language
    ethnic_church.country = country
    ethnic_church.religious_background = religious_background
    ethnic_church.build_note({content: notes[:notes]})
    ethnic_church.build_address(address)
    ethnic_church.save!
  end
end
