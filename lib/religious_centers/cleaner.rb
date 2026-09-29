module ReligiousCenters
  # Turns raw spreadsheet rows into cleaned records, recording every edit as a
  # Change so it can be reviewed, and every open question as a Flag.
  #
  # Decisions from a previous review round are passed in by change ID:
  # "Accept" (or blank) applies the change, "Reject" skips it, and any other
  # text replaces the proposed value (single-field changes only).
  class Cleaner
    Result = Struct.new(:records, :changes, :flags, :religion_mappings, keyword_init: true)

    ACCEPT = 'Accept'
    REJECT = 'Reject'

    SOURCE_COLUMNS = {
      name: 'NAME', street: 'StreetAddress', city: 'City', zip: 'ZIP', phone: 'Phone', extra: 'Column1',
      religion: 'ReligiousGroup', leader: 'Leader', emails: 'Emails', notes: 'Notes2'
    }.freeze

    # City spellings found in the source data and what they should be.
    CITY_FIXES = {
      'Burkank' => 'Burbank', 'Catsworth' => 'Chatsworth', 'Conoga Park' => 'Canoga Park', 'Daimand Bar' => 'Diamond Bar',
      'Fullertin' => 'Fullerton', 'Garanda Hills' => 'Granada Hills', 'La Puenta' => 'La Puente', 'Landcaster' => 'Lancaster',
      'Los Angelse' => 'Los Angeles', 'Los Anglese' => 'Los Angeles', 'LosAngeles' => 'Los Angeles', 'Mission Veijo' => 'Mission Viejo',
      'Onterio' => 'Ontario', 'Piverside' => 'Riverside', 'Rancho Cucamingo' => 'Rancho Cucamonga', 'Rowland Height' => 'Rowland Heights',
      'Santa Anna' => 'Santa Ana', 'Staton' => 'Stanton', 'Vaencia' => 'Valencia', 'Wesr Hollywood' => 'West Hollywood',
      'Westminister' => 'Westminster', 'ElMonte' => 'El Monte', 'BaldwinPark' => 'Baldwin Park', 'SantaMonica' => 'Santa Monica',
      'Monterey “Park' => 'Monterey Park', 'Bellflower' => 'Bellflower'
    }.freeze

    # Guesses that need a human look.
    CITY_GUESSES = {
      'Agoura' => ['Agoura Hills', 'medium'], 'Fountain' => ['Fontana', 'medium']
    }.freeze

    # Los Angeles neighborhoods written together with the city.
    LA_NEIGHBORHOOD = /\A(?:Hollywood\s*(?:\/|-)\s*Los Angeles|Los Angeles\s*(?:,|-)\s*(?:Echo Park|Eagle Rock))\z/i

    STATUS_NOTE = /\bhouse\b|open field|empty field|no such address|not at this address|moved to|being built|residential area|\bapp?artment\b|\bclosed\b|not been able to conf[ie]rm|\bstore\b|\bstor\b|car lot/i
    EMAIL = /[\w.+-]+@[\w-]+(?:\.[\w-]+)+/
    URL = %r{(?:https?://|www\.)\S+|\b[\w-]+(?:\.[\w-]+)*\.(?:org|com|net|edu|us|info)(?:/\S*)?}i
    PHONE = /\(?\b\d{3}\)?[\s.-]*\d{3}[\s.-]*\d{4}\b/

    def initialize(rows, decisions: {}, religion_decisions: {}, manual: [], geocoder: nil)
      @rows = rows
      @geocoder = geocoder
      @decisions = decisions
      @religion_decisions = religion_decisions
      @manual = manual.group_by { |entry| entry.fetch('row') }
      @changes = []
      @flags = []
    end

    def run
      mappings = religion_mappings
      records = @rows.map { |row| clean_row(row, mappings) }
      geocode(records) if @geocoder
      flag_duplicates(records)
      Result.new(records: records, changes: @changes, flags: @flags, religion_mappings: mappings)
    end

    # Mapping per distinct (squished) religion label, with any reviewer override applied.
    def religion_mappings
      labels = @rows.map { |row| Text.squish(row[SOURCE_COLUMNS[:religion]]).to_s }
      labels.tally.to_h do |label, count|
        mapping = ReligionMapper.map(label)
        decision = @religion_decisions[label].to_s.strip
        religions = if decision.empty? || decision.casecmp?(ACCEPT) then mapping.religions
                    elsif decision.casecmp?(REJECT) then [ReligionMapper::OTHER]
                    else decision.split(/\s*[,+]\s*/).reject(&:empty?)
                    end
        [label, { mapping: mapping, count: count, religions: religions, decision: decision.presence || ACCEPT }]
      end
    end

    private

    def clean_row(row, mappings)
      @row = row.fetch('row')
      raw = SOURCE_COLUMNS.transform_values { |column| row[column] }
      @record = {
        row: @row, name: raw_text(raw[:name]), street: raw_text(raw[:street]), city: raw_text(raw[:city]),
        zip: raw_text(raw[:zip]), phone: raw_text(raw[:phone]), website: nil, community: raw_text(raw[:leader]),
        leader: nil, email: raw_text(raw[:emails]), notes: raw_text(raw[:notes]), status: 'verified', name_uncertain: false
      }

      squish_fields
      clean_name
      clean_street
      clean_city
      clean_zip
      clean_phone
      clean_community
      split_emails_and_websites
      place_extra_column(raw_text(raw[:extra]))
      extract_contacts_from_notes
      suggest_status_from_notes
      apply_manual_suggestions
      assign_religions(mappings.fetch(Text.squish(raw[:religion]).to_s))
      flag_problems
      @record
    end

    def raw_text(value)
      return nil if value.nil?

      value.is_a?(Float) && value == value.floor ? value.to_i.to_s : value.to_s
    end

    # --- Rules -------------------------------------------------------------

    def squish_fields
      { name: ' - ', street: ' ', city: ' ', zip: '', phone: ' / ', community: ' ', email: ' ', notes: ' ' }.each do |field, joiner|
        before = @record[field]
        next if before.nil?

        after = Text.squish(before, joiner: joiner)
        next if after == before

        artifact = before.match?(Text::EXCEL_BREAK)
        propose("#{field}.squish", artifact ? 'Removed Excel line-break characters and extra spaces' : 'Trimmed extra spaces',
                'high', field => after)
      end
    end

    def clean_name
      name = @record[:name].to_s
      if name.match?(/\Azz\s*/i)
        propose('name.zz', 'Removed "ZZ" code: listed in a source but not found when checked in person',
                'high', name: name.sub(/\Azz\s*/i, ''), status: 'not_found')
      end

      name = @record[:name].to_s
      if name.match?(/\?\?|\s\?\s*\z|\?\s*\z/)
        cleaned = name.gsub(/\s*\?\?\s*/, ' ').sub(/\s*\?\s*\z/, '').strip
        propose('name.uncertain', 'Removed "??" marker; center flagged as name/details uncertain (admin-only flag)',
                'medium', name: cleaned, name_uncertain: true)
      end

      name = @record[:name].to_s
      punctuated = name.sub(/[\s,;-]+\z/, '')
      punctuated += ')' if punctuated.count('(') > punctuated.count(')')
      propose('name.punctuation', 'Fixed dangling punctuation or unclosed parenthesis', 'high', name: punctuated) if punctuated != name

      name = @record[:name].to_s
      propose('name.caps', 'Converted ALL CAPS to title case', 'medium', name: Text.title_case(name)) if Text.shouting?(name)
    end

    STREET_WORD_FIXES = { 'Wesr' => 'West', '3d' => '3rd', '2d' => '2nd' }.freeze

    def clean_street
      street = @record[:street].to_s
      return if street.empty?

      if (care_of = street[/\Ac\/o\s+[^,]+,\s*/i])
        propose('street.care_of', '"c/o" contact moved from the street address to notes', 'medium',
                street: street.delete_prefix(care_of), notes: join_notes(@record[:notes], "Address was #{care_of.sub(/,\s*\z/, '')}"))
      end

      street = @record[:street].to_s
      fixed = street.sub(/\A[^[:alnum:]]+/, '').sub(/[\s,;.]+\z/, '').gsub(/\b(?:#{STREET_WORD_FIXES.keys.join('|')})\b/, STREET_WORD_FIXES)
      propose('street.format', 'Fixed stray punctuation or a common street typo', 'high', street: fixed) if fixed != street
    end

    def clean_city
      city = @record[:city].to_s
      return if city.empty?

      if (zip = city[/\b9\d{4}\b/]) && Text.blank?(@record[:zip])
        propose('city.zip', 'ZIP code was typed into the City column', 'high', city: city.sub(zip, '').strip, zip: zip)
      end

      city = @record[:city].to_s
      stripped = city.sub(/\b9\d{4}\b/, '').sub(/[\s,]*\bca\b\.?[\s,]*\z/i, '').sub(/[\s,]+\z/, '').squeeze(' ').strip
      stripped = stripped.split.map { |word| word == word.downcase ? word.capitalize : word }.join(' ')
      stripped = stripped.split.map { |word| word.length > 3 && word == word.upcase ? word.capitalize : word }.join(' ')
      propose('city.format', 'Removed state/ZIP/punctuation from city or fixed capitalization', 'high', city: stripped) if stripped != city

      city = @record[:city].to_s
      if (fixed = CITY_FIXES[city]) && fixed != city
        propose('city.typo', 'City misspelled', 'high', city: fixed)
      elsif city.match?(LA_NEIGHBORHOOD)
        propose('city.neighborhood', 'Neighborhood written with the city; kept the city', 'medium', city: 'Los Angeles')
      elsif (guess, confidence = CITY_GUESSES[city])
        propose('city.guess', 'City name looks incomplete', confidence, city: guess)
      end
    end

    def clean_zip
      zip = @record[:zip].to_s
      return if zip.empty?

      if zip.match?(PHONE)
        sets = Text.blank?(@record[:phone]) ? { zip: nil, phone: zip } : { zip: nil, notes: join_notes(@record[:notes], "Number from ZIP column: #{zip}") }
        propose('zip.phone', 'A phone number was typed into the ZIP column', 'medium', **sets)
      elsif (digits = zip[/\A(9\d{4})[A-Za-z]+\z/, 1])
        propose('zip.letters', 'Stray letters after the ZIP code', 'high', zip: digits)
      elsif !zip.match?(/\A9\d{4}(-\d{4})?\z/)
        flag('zip.invalid', 'ZIP code looks wrong', "\"#{zip}\" isn't a 5-digit ZIP", 'The map lookup will suggest one if it finds the address')
      end
    end

    def clean_phone
      phone = @record[:phone].to_s
      return if phone.empty?

      numbers = phone.scan(PHONE)
      leftover = numbers.reduce(phone) { |text, number| text.sub(number, '') }.gsub(%r{[\s/;,.?]|\bor\b|\bI\b}, '')
      if numbers.any? && leftover.empty?
        formatted = numbers.map { |number| number.gsub(/\D/, '').then { "#{_1[0, 3]}-#{_1[3, 3]}-#{_1[6, 4]}" } }.uniq.join(' / ')
        propose('phone.format', 'Standardized phone number format', 'high', phone: formatted) if formatted != phone
      elsif phone.match?(/not in service/i)
        flag('phone.disconnected', 'Phone number not in service', phone, 'Consider marking the center unverified')
      elsif numbers.empty? || leftover.match?(/\d/)
        flag('phone.incomplete', 'Phone number looks incomplete or mistyped', phone, 'Left as-is')
      end
    end

    def clean_community
      community = @record[:community]
      return if community.nil?

      result = CommunityNormalizer.normalize(community)
      if result.uncertain
        propose('community.uncertain', result.reason, result.confidence,
                community: nil, notes: join_notes(@record[:notes], "Community (unconfirmed): #{result.value}"))
      elsif result.value != community
        propose('community.normalize', result.reason, result.confidence, community: result.value)
      end
    end

    def split_emails_and_websites
      text = @record[:email]
      return if text.nil?

      emails = text.scan(EMAIL)
      without_emails = emails.reduce(text) { |rest, email| rest.sub(email, ' ') }
      urls = without_emails.scan(URL).map { |url| url.sub(/[.,;]+\z/, '') }
      leftover = urls.reduce(without_emails) { |rest, url| rest.sub(url, ' ') }.gsub(/[\s,;\/]/, '')
      return if urls.empty? && (emails.join(', ') == text)

      sets = { email: emails.join(', ').presence }
      sets[:website] = normalize_url(urls.first) if urls.any?
      sets[:notes] = join_notes(@record[:notes], "Other websites: #{urls.drop(1).join(', ')}") if urls.size > 1
      sets[:notes] = join_notes(sets[:notes] || @record[:notes], "From Emails column: #{text}") unless leftover.empty?
      reason = urls.any? ? 'Website was in the Emails column; moved to Website (public)' : 'Cleaned email list'
      propose('email.split', reason, leftover.empty? ? 'high' : 'medium', **sets)
    end

    # The unlabeled "Column1" holds a mix of emails, websites, phones, and community notes.
    def place_extra_column(value)
      value = Text.squish(value)
      return if value.nil?

      sets, reason = if value.match?(/\A#{EMAIL}\z/)
                       [{ email: [@record[:email], value].compact.join(', ') }, 'Email from the unlabeled Column1']
                     elsif value.match?(/\A#{URL}\z/)
                       [Text.blank?(@record[:website]) ? { website: normalize_url(value) } : { notes: join_notes(@record[:notes], "Link: #{value}") }, 'Link from the unlabeled Column1']
                     elsif value.match?(/\A#{PHONE}\z/)
                       [Text.blank?(@record[:phone]) ? { phone: value } : { phone: "#{@record[:phone]} / #{value}" }, 'Phone number from the unlabeled Column1']
                     elsif value.casecmp?('x')
                       flag('extra.x', 'Column1 just says "x"', 'Unknown meaning', 'Ignored')
                       return
                     else
                       [{ community: [@record[:community], value].compact.join('; ') }, 'Community/tradition from the unlabeled Column1']
                     end
      applied = propose('extra.place', reason, 'medium', **sets)
      @record[:notes] = join_notes(@record[:notes], "Column1: #{value}") unless applied
    end

    def extract_contacts_from_notes
      notes = @record[:notes].to_s
      { email: EMAIL, phone: PHONE, website: URL }.each do |field, pattern|
        next unless Text.blank?(@record[field]) && (found = notes[pattern])

        value = field == :website ? normalize_url(found) : found
        propose("notes.#{field}", "#{field.to_s.capitalize} was written in the notes", 'medium', field => value)
      end
    end

    def suggest_status_from_notes
      return unless @record[:status] == 'verified'

      notes = @record[:notes].to_s
      return unless (match = notes[STATUS_NOTE])

      # Notes like "Temple in House" describe a real place, so those are only a weak signal.
      confidence = notes.match?(/temple|mosque|masjid|\bsign\b|activities|meets/i) ? 'low' : 'medium'
      propose('status.notes', "Notes suggest this isn't an active center (\"#{match}\"); admin-only until verified",
              confidence, status: 'unverified')
    end

    def apply_manual_suggestions
      Array(@manual[@row]).each_with_index do |entry, index|
        if entry['flag']
          flag("manual.#{index}", entry['flag'], entry['details'], entry['suggestion'])
        else
          sets = entry.fetch('sets', {}).transform_keys(&:to_sym)
          sets[:notes] = join_notes(sets.fetch(:notes, @record[:notes]), entry['append_notes']) if entry['append_notes']
          propose("manual.#{index}", entry.fetch('reason'), entry.fetch('confidence', 'medium'), **sets)
        end
      end
    end

    def assign_religions(mapping)
      @record[:religions] = mapping[:religions]
      branch = mapping[:mapping].branch
      return unless branch && mapping[:decision].casecmp?(ACCEPT)
      return if @record[:community].to_s.downcase.include?(branch.downcase)

      propose('community.branch', "\"#{branch}\" from the religion label", 'high',
              community: [@record[:community], branch].compact.join(', '))
    end

    def flag_problems
      if po_box?(@record[:street])
        flag('street.po_box', 'Mailing address only (P.O. box)', @record[:street], 'Listed without a map location')
      elsif Text.blank?(@record[:street])
        flag('street.missing', 'No street address', nil, 'Listed without a map location')
      end
    end

    def flag_duplicates(records)
      records.group_by { |r| [r[:name].to_s.downcase.gsub(/\W/, ''), r[:street].to_s.downcase.gsub(/\W/, '')] }
             .select { |_, group| group.size > 1 }.each_value do |group|
        group.each do |record|
          others = (group - [record]).map { |r| r[:row] }.join(', ')
          @flags << Flag.new(id: "R#{record[:row]}.duplicate", row: record[:row], center: record[:name], issue: 'Possible duplicate',
                             details: "Same name and address as row(s) #{others}", suggestion: 'Keep one')
        end
      end
    end

    def geocode(records)
      mappable = records.reject { |record| Text.blank?(record[:street]) || po_box?(record[:street]) }
      results = @geocoder.geocode(mappable.to_h { |record| [record[:row], record.slice(:street, :city, :zip)] })

      mappable.each do |record|
        @row = record[:row]
        @record = record
        result = results.fetch(@row)
        unless result.matched?
          record[:geocode_match] = result.match == 'Tie' ? 'Ambiguous' : 'Not found'
          flag('geocode.none', 'Map lookup could not place this address', [record[:street], record[:city], record[:zip]].compact.join(', '),
               'Check the street and city; the center will be listed without a map pin')
          next
        end

        zip = record[:zip].to_s
        if zip.match?(/\A9\d{4}/) && result.zip && zip[0, 3] != result.zip[0, 3]
          # A distant ZIP usually means the lookup found a same-named street in another city.
          record[:geocode_match] = 'Conflicting'
          flag('geocode.conflict', 'Map lookup found a different area than the ZIP', "Sheet has #{zip}; lookup matched #{result.matched_address}",
               'Left off the map until the address is checked')
          next
        end

        record.merge!(latitude: result.latitude, longitude: result.longitude, geocode_match: result.exact ? 'Exact' : 'Approximate')
        if result.zip && !zip.match?(/\A9\d{4}(-\d{4})?\z/)
          propose('zip.geocode', "ZIP #{zip.empty? ? 'missing' : "\"#{zip}\" invalid"}; filled from the map lookup (#{result.matched_address})",
                  'medium', zip: result.zip)
        end
      end
    end

    # --- Helpers -----------------------------------------------------------

    def po_box?(street)
      street.to_s.match?(/p\.?\s*o\.?\s*box|\Abox\s+\d/i)
    end

    # Records a change and applies it unless the reviewer rejected it.
    # Returns true if the change was applied.
    def propose(key, rule, confidence, **sets)
      id = "R#{@row}.#{key}"
      decision = @decisions[id].to_s.strip
      before = sets.keys.map { |field| @record[field] }
      change = Change.new(id: id, row: @row, center: display_name, field: sets.keys.join(' + '),
                          before: describe(sets.keys, before), after: describe(sets.keys, sets.values),
                          sets: sets, rule: rule, confidence: confidence)
      @changes << change

      return false if decision.casecmp?(REJECT)

      if decision.empty? || decision.casecmp?(ACCEPT)
        @record.merge!(sets)
      elsif change.single_field?
        @record[sets.keys.first] = decision
      else
        @record.merge!(sets)
      end
      true
    end

    def flag(key, issue, details, suggestion)
      @flags << Flag.new(id: "R#{@row}.#{key}", row: @row, center: display_name, issue: issue, details: details, suggestion: suggestion)
    end

    def display_name
      Text.squish(@record[:name]).to_s.sub(/\Azz\s*/i, '')
    end

    def describe(fields, values)
      return format_value(values.first) if fields.size == 1

      fields.zip(values).map { |field, value| "#{field}: #{format_value(value)}" }.join("\n")
    end

    def format_value(value)
      value.nil? ? '(blank)' : value.to_s.gsub(Text::EXCEL_BREAK, '↵')
    end

    def join_notes(notes, addition)
      [notes, addition].compact_blank.join("\n")
    end

    def normalize_url(url)
      url = url.sub(/[.,;]+\z/, '')
      url.match?(%r{\Ahttps?://}i) ? url : "http://#{url}"
    end
  end
end
