require 'json'

module ReligiousCenters
  # Loads the cleaned dataset (JSON written by the review task) into the
  # database. Safe to re-run: centers are matched by their source row.
  class Importer
    CENTER_FIELDS = %i[name street city zip phone website community leader email notes status name_uncertain
                       latitude longitude geocode_match].freeze

    def self.import(path)
      new(JSON.parse(File.read(path), symbolize_names: true)).import
    end

    def initialize(records)
      @records = records
    end

    def import
      ReligiousCenter.transaction do
        religions = import_religions
        @records.each do |record|
          center = ReligiousCenter.find_or_initialize_by(source_row: record.fetch(:row))
          center.update!(record.slice(*CENTER_FIELDS))
          center.religions = record.fetch(:religions).map { |name| religions.fetch(name) }
        end
        ReligiousCenter.where.not(source_row: nil).where.not(source_row: @records.map { _1[:row] }).destroy_all
      end
      { centers: @records.size, religions: ReligiousCenter.joins(:religions).distinct.count('religions.id') }
    end

    private

    def import_religions
      @records.flat_map { _1[:religions] }.uniq.to_h do |name|
        religion = Religion.find_or_initialize_by(name: name)
        religion.admin_only = name == ReligionMapper::OTHER
        religion.save!
        [name, religion]
      end
    end
  end
end
