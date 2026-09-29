module ReligiousCenters
  # Maps the spreadsheet's free-text religion labels to canonical religions.
  class ReligionMapper
    OTHER = 'Other'

    RELIGIONS = [
      "Bahá'í Faith", 'Buddhism', 'Confucianism', 'Druze', 'Hinduism', 'Islam', 'Jainism',
      'Judaism', 'Shinto', 'Sikhism', 'Taoism', 'Tenrikyo', 'Zoroastrianism', OTHER
    ].freeze

    # Word stems (after lowercasing) that identify each religion, including the
    # misspellings found in the source data.
    STEMS = {
      'Buddhism' => %w[buddhis buddhisn buddisism],
      'Judaism' => %w[juda],
      'Islam' => %w[islam isalm ialam],
      'Hinduism' => %w[hindu himdu],
      'Sikhism' => %w[sikh],
      'Taoism' => %w[tao daoism daosim daioism],
      "Bahá'í Faith" => %w[baha],
      'Jainism' => %w[jain],
      'Shinto' => %w[shinto],
      'Zoroastrianism' => %w[zoroastr],
      'Confucianism' => %w[confuci],
      'Tenrikyo' => %w[tenrikyo],
      'Druze' => %w[druze]
    }.freeze

    # Branches that are kept as a community/tradition note instead of a separate page.
    BRANCHES = { /\bshi[ae]\b|\bshai\b/i => 'Shia', /\bsunni\b/i => 'Sunni', /\bsufi\b/i => 'Sufi',
                 /\bamerican\b/i => 'American', /\bindia\b/i => 'Indian' }.freeze

    # Labels too vague for their own page; they go to the admin-only Other page.
    VAGUE = /new[\s-]*age|new[\s-]*religion|native religion/i

    Mapping = Struct.new(:label, :religions, :branch, :confidence, :reason, keyword_init: true)

    def self.map(label)
      new.map(label)
    end

    def map(label)
      text = Text.squish(label).to_s
      down = text.downcase
      found = STEMS.select { |_, stems| stems.any? { |stem| down.include?(stem) } }.keys
      branch = BRANCHES.find { |pattern, _| text =~ pattern }&.last

      if text =~ VAGUE && found.empty?
        return Mapping.new(label: text, religions: [OTHER], branch: nil, confidence: 'high',
                           reason: 'Too vague for its own page yet; goes on the admin-only Other page')
      end
      if found.empty?
        return Mapping.new(label: text, religions: [OTHER], branch: nil, confidence: 'low', reason: 'Unrecognized label')
      end

      confidence = 'high'
      reasons = []
      reasons << 'Spelling/wording normalized' unless found == [text]
      if found.size > 1
        confidence = 'medium'
        reasons << "Center listed under #{found.size} religions; it will appear on each page"
      end
      if text =~ VAGUE
        confidence = 'medium'
        reasons << "\"New Age\" part dropped"
      end
      reasons << "#{branch} kept as the center's community/tradition" if branch
      Mapping.new(label: text, religions: found, branch: branch, confidence: confidence, reason: reasons.join('; ').presence || 'Already canonical')
    end
  end
end
