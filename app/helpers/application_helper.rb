module ApplicationHelper
  def show_footer?
    return true unless %w[sessions passwords].include?(controller_name)
    return false
  end
end
