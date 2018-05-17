class Address < ApplicationRecord
  belongs_to :ethnic_church

  def full_address
    return "#{street}\n#{city}, CA #{zip}" if street && city && zip
    return "#{city}, CA" if city
    'CA'
  end
end
