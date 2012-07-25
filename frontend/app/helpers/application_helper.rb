module ApplicationHelper
  def format_id(s)
    IDUtils::s_to_a(s).inspect
  end
end
