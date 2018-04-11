require 'csv'

headers = %i[street city country website email language name notes pastors_name phone religious_background]

CSV.foreach(ARGV[0], headers: headers) do |csv|
  printf "\rProcessing line: %s", $INPUT_LINE_NUMBER

  hash = csv.to_h.transform_values(&:to_s).transform_values(&:squish).transform_values { |value| value if value.present? }

  # clean up emails incorrectly placed in website field
  hash[:email] = hash.delete(:website) if hash[:website] =~ Devise.email_regexp && hash[:email].blank?
  hash[:website] = hash[:website]

  ethnic_church = hash.slice(:name, :phone, :website, :email, :pastors_name)
  language_names = hash[:language].to_s.split(/\s*,\s*/)
  country = hash.slice(:country)
  religious_background = hash.slice(:religious_background)
  notes = hash.slice(:notes)
  address = hash.slice(:street, :city, :zip)

  # city, state, and zip were all stuffed into city so cleaning up
  city, _, zip = address[:city].to_s.split(/( [Cc][Aa] | [Cc][Aa]\z)/)

  address[:city] = city
  address[:zip] = zip

  EthnicChurch.transaction do
    country = Country.find_or_initialize_by(name: country[:country])
    religious_background = ReligiousBackground.find_or_initialize_by(persuasion: religious_background[:religious_background])

    ethnic_church = EthnicChurch.new(ethnic_church)

    ethnic_church.languages = language_names
    ethnic_church.country = country
    ethnic_church.religious_background = religious_background
    ethnic_church.build_note(content: notes[:notes])
    ethnic_church.build_address(address)
    ethnic_church.save!
  end
end
puts
