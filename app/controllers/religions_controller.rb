class ReligionsController < ApplicationController
  def index
    @religions = Religion.visible_to(admin_signed_in?)
    @center_counts = ReligionMembership.joins(:religious_center)
                                       .merge(ReligiousCenter.visible_to(admin_signed_in?))
                                       .group(:religion_id).count
  end

  def show
    # Admin-only religions, and religions with no verified centers, are hidden from the public.
    @religion = Religion.visible_to(admin_signed_in?).find_by!(slug: params[:id])
    @religious_centers = @religion.religious_centers.visible_to(admin_signed_in?).order(:city, :name)
  end
end
