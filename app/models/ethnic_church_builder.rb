class EthnicChurchBuilder
  def self.instantiate(objects)
    @ec = objects[:ethnic_church]
    @ec.languages = objects[:languages]
    @ec.country = objects[:country]
    @ec.religious_background = objects[:religious_background]
    @ec.address = objects[:address]
    @ec.note = objects[:note]
    @ec
  end
end
