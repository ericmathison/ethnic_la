class Address < ApplicationRecord
  belongs_to :ethnic_church

  def full_address
    "#{self.street}\n#{self.city}, #{self.state} #{self.zip}"
  end
end
