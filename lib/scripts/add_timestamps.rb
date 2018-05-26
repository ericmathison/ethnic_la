date = DateTime.now

class EthnicChurchesLanguage < ApplicationRecord; end

[Address, Country, EthnicChurch, EthnicChurchesLanguage, Language, Note, ReligiousBackground].each do |klass|
  klass.update_all(created_at: date, updated_at: date)
end
