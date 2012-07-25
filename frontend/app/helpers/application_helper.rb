module ApplicationHelper
  def format_id(s)
    IDUtils::s_to_a(s).inspect
  end
  
  def include_controller_js
   javascript_include_tag "#{controller.controller_name}" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js")
  end  
end
