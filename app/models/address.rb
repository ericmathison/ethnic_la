class Address < ApplicationRecord
  belongs_to :ethnic_church

  def full_address
    "#{street}\n#{city}, #{state} #{zip}"
  end
end
