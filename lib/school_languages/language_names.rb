module SchoolLanguages
  # CDE switched language codes in 2023-24, from its own two-character codes
  # ("01" Spanish) to ISO 639-2 codes ("spa" Spanish; Castilian), and some ISO
  # labels change between years. This maps both onto one name per language so
  # a language can be followed across years.
  module LanguageNames
    # Codes for "other", "uncoded", "undetermined", and "multiple languages",
    # which can't be mapped as a language.
    UNMAPPABLE = %w[99 mis und mul].freeze

    CDE_CODES = {
      '01' => 'Spanish', '02' => 'Vietnamese', '03' => 'Cantonese', '04' => 'Korean',
      '05' => 'Filipino (Tagalog)', '06' => 'Portuguese', '07' => 'Mandarin', '08' => 'Japanese',
      '09' => 'Khmer (Cambodian)', '10' => 'Lao', '11' => 'Arabic', '12' => 'Armenian', '13' => 'Burmese',
      '15' => 'Dutch', '16' => 'Persian (Farsi)', '17' => 'French', '18' => 'German', '19' => 'Greek',
      '20' => 'Chamorro', '21' => 'Hebrew', '22' => 'Hindi', '23' => 'Hmong', '24' => 'Hungarian',
      '25' => 'Ilocano', '26' => 'Indonesian', '27' => 'Italian', '28' => 'Punjabi', '29' => 'Russian',
      '30' => 'Samoan', '32' => 'Thai', '33' => 'Turkish', '34' => 'Tongan', '35' => 'Urdu',
      '36' => 'Cebuano', '38' => 'Ukrainian', '39' => 'Chaozhou (Teochew)', '40' => 'Pashto',
      '41' => 'Polish', '42' => 'Assyrian', '43' => 'Gujarati', '44' => 'Mien', '45' => 'Romanian',
      '46' => 'Taiwanese', '47' => 'Lahu', '48' => 'Marshallese', '49' => 'Mixteco', '50' => 'Khmu',
      '51' => 'Kurdish', '52' => 'Bosnian, Croatian, and Serbian', '53' => 'Toishanese', '54' => 'Chaldean',
      '56' => 'Albanian', '57' => 'Tigrinya', '60' => 'Somali', '61' => 'Bengali', '62' => 'Telugu',
      '63' => 'Tamil', '64' => 'Marathi', '65' => 'Kannada', '66' => 'Amharic', '67' => 'Bulgarian',
      '68' => 'Kikuyu', '69' => 'Kashmiri', '70' => 'Swedish', '71' => 'Zapoteco', '72' => 'Uzbek',
      '73' => 'Haitian Creole', '74' => 'Kachin', '75' => 'Karen', '76' => 'Nepali', '77' => 'Swahili',
      '78' => 'Oromo', '79' => 'Lingala', '80' => 'Kinyarwanda', '82' => 'Dinka', '83' => 'Afrikaans',
      '85' => 'Afro-Asiatic languages', '86' => 'Berber languages', '87' => 'Catalan',
      '88' => 'Central American Indian languages', '89' => 'English-based creoles',
      '90' => 'French-based creoles', '91' => 'Czech', '92' => 'Danish', '93' => 'Fijian', '94' => 'Finnish',
      '95' => 'Hawaiian', '96' => 'Icelandic', '98' => 'Igbo',
      'A1' => 'Iranian languages', 'A2' => 'Konkani', 'A3' => 'Latvian', 'A4' => 'Lithuanian', 'A5' => 'Malay',
      'A6' => 'Malayalam', 'A7' => 'Mayan languages', 'A8' => 'Mongolian', 'A9' => 'Nahuatl',
      'B1' => 'Navajo', 'B2' => 'North American Indian languages', 'B3' => 'Norwegian', 'B4' => 'Oriya',
      'B5' => 'Kapampangan', 'B6' => 'Sinhala', 'B7' => 'Slovak', 'B8' => 'Twi', 'B9' => 'Yoruba'
    }.freeze

    # ISO codes whose name differs from the ISO label (before any ";").
    ISO_CODES = {
      'spa' => 'Spanish', 'cmn' => 'Mandarin', 'yue' => 'Cantonese', 'per' => 'Persian (Farsi)',
      'pan' => 'Punjabi', 'pus' => 'Pashto', 'phi' => 'Filipino (Tagalog)', 'fil' => 'Filipino (Tagalog)',
      'tgl' => 'Filipino (Tagalog)', 'oto' => 'Mixteco', 'qad' => 'Mixteco', 'zap' => 'Zapoteco',
      'hmn' => 'Hmong', 'mkh' => 'Khmer (Cambodian)', 'khm' => 'Khmer (Cambodian)', 'cld' => 'Chaldean',
      'syr' => 'Assyrian', 'sit' => 'Toishanese', 'qab' => 'Chaozhou (Teochew)', 'qaa' => 'Taiwanese',
      'chi' => 'Chinese (other)', 'myn' => 'Mayan languages', 'hat' => 'Haitian Creole',
      'ton' => 'Tongan', 'rum' => 'Romanian', 'ilo' => 'Ilocano', 'ceb' => 'Cebuano', 'cha' => 'Chamorro',
      'yao' => 'Mien', 'kur' => 'Kurdish', 'dut' => 'Dutch', 'gre' => 'Greek', 'ota' => 'Turkish',
      'srp' => 'Bosnian, Croatian, and Serbian', 'hrv' => 'Bosnian, Croatian, and Serbian',
      'bos' => 'Bosnian, Croatian, and Serbian', 'hbs' => 'Bosnian, Croatian, and Serbian',
      'cpe' => 'English-based creoles', 'cpf' => 'French-based creoles', 'cpp' => 'Portuguese-based creoles',
      'crp' => 'Creoles and pidgins (other)', 'kac' => 'Kachin', 'kik' => 'Kikuyu', 'kar' => 'Karen',
      'kjg' => 'Khmu', 'nah' => 'Nahuatl', 'nav' => 'Navajo', 'pam' => 'Kapampangan', 'sin' => 'Sinhala',
      'cai' => 'Central American Indian languages', 'nai' => 'North American Indian languages',
      'ira' => 'Iranian languages', 'kir' => 'Kyrgyz', 'uig' => 'Uyghur', 'nno' => 'Norwegian',
      'gsw' => 'Swiss German', 'new' => 'Newari', 'ful' => 'Fula', 'crh' => 'Crimean Tatar',
      'rup' => 'Aromanian', 'sgn' => 'Sign languages (other)', 'bat' => 'Baltic languages (other)'
    }.freeze

    # Returns nil for codes that can't be mapped as a language.
    def self.for(code, label)
      code = code.to_s.strip
      return if UNMAPPABLE.include?(code)

      if code.match?(/\A[0-9A-Z]{2}\z/)
        CDE_CODES.fetch(code) { raise ArgumentError, "Unknown CDE language code #{code} (#{label})" }
      else
        ISO_CODES.fetch(code) { label.to_s.split(';').first.strip }
      end
    end
  end
end
