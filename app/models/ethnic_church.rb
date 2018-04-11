class EthnicChurch < ApplicationRecord
  has_and_belongs_to_many :languages
  has_one :address
  has_one :note
  belongs_to :country
  belongs_to :religious_background

  validates :email, format: { with: Devise.email_regexp }, allow_nil: true

  def languages=(names)
    language_records = names.map do |language|
      next if language.blank?
      Language.find_or_initialize_by(name: language)
    end.compact

    super(language_records)
  end
end
