module ReligiousCenters
  module Text
    module_function

    # Excel stores in-cell line breaks from some sources as the literal "_x000B_".
    EXCEL_BREAK = /_x000B_/

    # Collapse whitespace and Excel line-break artifacts. Line breaks in the
    # middle of a value become `joiner`; leading/trailing ones are dropped.
    def squish(value, joiner: ' ')
      return nil if value.nil?

      text = value.is_a?(Float) && value == value.floor ? value.to_i.to_s : value.to_s
      text.split(EXCEL_BREAK).map { |part| part.gsub(/[[:space:]]+/, ' ').strip }.reject(&:empty?).join(joiner).presence
    end

    def blank?(value)
      value.nil? || value.to_s.strip.empty?
    end

    ACRONYMS = %w[SGI USA ISKCON FHA ZCLA SRF CMC ABC BSC IBMC ICIE ICSC MSA JFC ZAC LA CA US OC AUM UWEST].freeze
    SMALL_WORDS = %w[of and the in at for to a an].freeze

    # Letters that are mostly uppercase, e.g. "TEMPLE BETH AM".
    def shouting?(text)
      letters = text.to_s.scan(/[[:alpha:]]/)
      letters.size >= 6 && letters.count { |c| c =~ /[[:upper:]]/ } >= letters.size * 0.8
    end

    def title_case(text)
      words = text.split(/(\s+)/)
      first_word = true
      words.map do |word|
        next word if word =~ /\A\s+\z/

        result = title_case_word(word, first_word)
        first_word = false
        result
      end.join
    end

    def title_case_word(word, first_word)
      return word.downcase if !first_word && SMALL_WORDS.include?(word.downcase)

      word.split(/(-)/).map { |part| part == '-' ? part : title_case_part(part) }.join
    end

    def title_case_part(part)
      bare = part.gsub(/[^[:alnum:]]/, '')
      return part if part == part.upcase && ACRONYMS.include?(bare.upcase)

      # Capitalize the first letter (and after a slash or opening bracket); letters after an apostrophe stay lowercase (B'nai).
      part.downcase.gsub(/(\A|[\/(“"])([[:alpha:]])/) { "#{$1}#{$2.upcase}" }
    end
  end
end
