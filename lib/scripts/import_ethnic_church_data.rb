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

  EthnicChurch.create(hash)
end
