# Cleanup and import pipeline for the religious centers spreadsheet.
#
#   bin/rails religious_centers:review  # clean, geocode, and write the review workbook
#   bin/rails religious_centers:import  # load the reviewed data into the database
#
# The source spreadsheet, review workbook, and cleaned data contain private
# details, so they live in the gitignored data/ directory (or the Desktop),
# never in git.
module ReligiousCenters
  # One proposed edit to a record. `sets` maps output fields to new values; a
  # change that moves text between fields sets more than one.
  Change = Struct.new(:id, :row, :center, :field, :before, :after, :sets, :rule, :confidence, keyword_init: true) do
    def single_field?
      sets.size == 1
    end
  end

  # Something the cleanup can't decide on its own.
  Flag = Struct.new(:id, :row, :center, :issue, :details, :suggestion, keyword_init: true)

  CONFIDENCES = %w[high medium low].freeze

  FIELDS = %i[name street city zip phone website community leader email notes status name_uncertain].freeze
end

require_relative 'religious_centers/text'
require_relative 'religious_centers/religion_mapper'
require_relative 'religious_centers/community_normalizer'
require_relative 'religious_centers/cleaner'
require_relative 'religious_centers/census_geocoder'
