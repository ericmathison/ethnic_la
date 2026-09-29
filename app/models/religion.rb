class Religion < ApplicationRecord
  has_many :religion_memberships, dependent: :destroy
  has_many :religious_centers, through: :religion_memberships

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation { self.slug = name.delete("'’").parameterize if slug.blank? && name.present? }

  # Religions shown in the public menu: not admin-only, with at least one verified center
  scope :publicly_listed, -> { where(admin_only: false).where(id: ReligionMembership.joins(:religious_center).merge(ReligiousCenter.verified).select(:religion_id)) }

  def self.visible_to(admin)
    admin ? order(:admin_only, :name) : publicly_listed.order(:name)
  end

  def to_param
    slug
  end
end
