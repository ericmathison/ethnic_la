module ApplicationHelper
  def show_footer?
    return true unless %w[sessions passwords].include?(controller_name)
    return false
  end

  # Ethnic churches (Christianity) are the site's home page and default religion.
  def viewing_ethnic_churches?
    controller_name.in?(%w[ethnic_churches languages])
  end

  def viewing_language_map?
    controller_name == 'school_languages'
  end

  # The home page, church language pages, and religion pages
  def viewing_religions?
    viewing_ethnic_churches? || controller_name == 'religions'
  end

  NAV_ICONS = {
    # A building with a peaked roof and an arched door
    place_of_worship: '<path d="M3 21V10l9-6 9 6v11z"/><path d="M10 21v-4a2 2 0 0 1 4 0v4"/><path d="M12 1v3"/>',
    map_pin: '<path d="M12 21s-7-6.3-7-12a7 7 0 0 1 14 0c0 5.7-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/>'
  }.freeze

  def nav_icon(name)
    tag.svg(NAV_ICONS.fetch(name).html_safe, class: 'nav-icon', viewBox: '0 0 24 24', width: 16, height: 16, fill: 'none',
            stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round', aria: { hidden: true })
  end

  # nil when the page isn't about a religion
  def current_religion_label
    return @religion.name if @religion
    return if viewing_language_map?
    return 'All' if controller_name == 'religions'

    'Christianity'
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
