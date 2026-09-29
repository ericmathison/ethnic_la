module ApplicationHelper
  def show_footer?
    return true unless %w[sessions passwords].include?(controller_name)
    return false
  end

  # Religions listed in the navigation menu for the current visitor
  def menu_religions
    @menu_religions ||= Religion.visible_to(admin_signed_in?).to_a
  end

  def church_map_points(ethnic_churches)
    ethnic_churches.includes(:address).filter_map do |church|
      address = church.address
      next unless address&.latitude && address.longitude

      { lng: address.longitude, lat: address.latitude, name: church.name }
    end
  end

  def center_map_points(religious_centers)
    religious_centers.select(&:mappable?).map do |center|
      { lng: center.longitude, lat: center.latitude, name: center.name, status: center.status }
    end
  end

  # Only link to http(s) URLs; show them without the scheme.
  def website_link(url)
    return if url.blank?
    return url unless url.match?(%r{\Ahttps?://}i)

    link_to(url.sub(%r{\Ahttps?://(www\.)?}i, '').chomp('/'), url, target: '_blank', rel: 'noopener nofollow')
  end
end
