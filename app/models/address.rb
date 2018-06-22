class Address < ApplicationRecord
  belongs_to :ethnic_church

  def full_address
    return "#{street}\n#{city}, CA #{zip}" if street.present? && city.present? && zip.present?
    return "#{street}\n#{city}, CA" if street.present? && city.present?
    return "#{city}, CA" if city.present?
    'CA'
  end
end
