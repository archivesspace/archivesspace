module ApplicationHelper
  def format_id(s)
    IDUtils::s_to_a(s).inspect
  end
  
  def include_controller_js
   javascript_include_tag "#{controller.controller_name}" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js.erb")
  end
  
  def include_controller_css
   stylesheet_link_tag "#{controller.controller_name}" if File.exists?("#{Rails.root}/app/assets/stylesheets/#{controller_name}.css") ||  File.exists?("#{Rails.root}/app/assets/stylesheets/#{controller_name}.css.less")
  end
  
end
