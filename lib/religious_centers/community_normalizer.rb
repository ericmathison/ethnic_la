module ReligiousCenters
  # Cleans the spreadsheet's "Leader" column, which mostly holds the ethnic
  # community or tradition of a center ("Vietnamese", "Tibetan Karma Kagyu").
  class CommunityNormalizer
    Result = Struct.new(:value, :confidence, :reason, :uncertain, keyword_init: true)

    WORD_FIXES = {
      'afgan' => 'Afghan', 'afghani' => 'Afghan', 'bermese' => 'Burmese', 'burnese' => 'Burmese',
      'chiinese' => 'Chinese', 'japaniese' => 'Japanese', 'vietmanese' => 'Vietnamese',
      'vietnamesevietnam' => 'Vietnamese', 'mhayana' => 'Mahayana', 'mahanana' => 'Mahayana',
      'theravaha' => 'Theravada', 'linage' => 'lineage', 'provience' => 'Province',
      'manderin' => 'Mandarin', 'layo' => 'Lao', 'zeb' => 'Zen', 'fukian' => 'Fujian'
    }.freeze

    COUNTRIES = {
      'sir lanka' => 'Sri Lankan', 'sri lanka' => 'Sri Lankan', 'sir linka' => 'Sri Lankan', 'china' => 'Chinese',
      'india' => 'Indian', 'japan' => 'Japanese', 'tibet' => 'Tibetan', 'taiwan' => 'Taiwanese', 'iran' => 'Iranian',
      'bangladesh' => 'Bangladeshi', 'lebanon' => 'Lebanese', 'laos' => 'Laotian', 'nepal' => 'Nepali',
      'thailand' => 'Thai', 'cambodia' => 'Cambodian', 'vietnam' => 'Vietnamese', 'pakistan' => 'Pakistani'
    }.freeze

    UNCERTAIN = /\?|\bpossible\b|\blooks\b|\bprobably\b|sign in many/i

    def self.normalize(value)
      new.normalize(value)
    end

    def normalize(value)
      text = Text.squish(value).to_s
      return Result.new(value: nil, confidence: 'high', reason: 'Placeholder dash removed') if text.match?(/\A[-–]+\z/)
      if text.match?(UNCERTAIN)
        return Result.new(value: text, confidence: 'medium', uncertain: true,
                          reason: 'Uncertain guess; moved to private notes instead of the public community')
      end

      reasons = []
      fixed = text.gsub(/[[:alpha:]]+/) { |word| WORD_FIXES[word.downcase] || word }
      reasons << 'Typo fixed' if fixed != text

      unless fixed.match?(/\bfrom\b/i)
        demonyms = fixed.gsub(/\b(#{COUNTRIES.keys.sort_by { -_1.length }.map { Regexp.escape(_1) }.join('|')})\b(?![^(]*\))(?!\s+area)/i) { COUNTRIES[$1.downcase] }
        reasons << 'Country name changed to community name' if demonyms != fixed
        fixed = demonyms
      end

      spaced = fixed.gsub(/\s+,/, ',').gsub(/\s+-\s*|\s*-\s+/, ' - ').gsub(%r{\s*/\s*}, '/').sub(/[\s,.-]+\z/, '')
      reasons << 'Punctuation spacing' if spaced != fixed && reasons.empty?
      Result.new(value: spaced, confidence: 'high', reason: reasons.join('; ').presence)
    end
  end
end
