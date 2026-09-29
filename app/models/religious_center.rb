class ReligiousCenter < ApplicationRecord
  STATUSES = {
    'verified' => 'Verified',
    'unverified' => 'Unverified',
    'not_found' => 'Listed but not found in person'
  }.freeze

  has_many :religion_memberships, dependent: :destroy
  has_many :religions, through: :religion_memberships

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES.keys }

  scope :verified, -> { where(status: 'verified') }

  def self.visible_to(admin)
    admin ? all : verified
  end

  def verified?
    status == 'verified'
  end

  def status_label
    STATUSES.fetch(status)
  end

  def mappable?
    latitude.present? && longitude.present?
  end

  def full_address
    [street, [city, ['CA', zip].compact_blank.join(' ')].compact_blank.join(', ')].compact_blank.join("\n")
  end
end
