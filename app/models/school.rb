class School < ApplicationRecord
  has_many :school_language_counts, dependent: :delete_all

  validates :cds_code, presence: true, uniqueness: true
  validates :name, presence: true
end
