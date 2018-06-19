# This cleans up some strange data. Apparently names begining with 'zz' were
# indicating an ethnic church whose existence was unconfirmed. This was also
# verified to apply to names with a question mark.

EthnicChurch.where("substring(name, '..') = 'zz' OR name ILIKE '%?%'").find_each do |ec|
  ec.unconfirmed = true
  ec.name = ec.name[2..-1] if ec.name[/\Azz/]
  ec.save!
end
