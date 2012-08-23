module ApplicationHelper

  def include_controller_js
   scripts = ""

   scripts += javascript_include_tag "#{controller.controller_name}" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.js.erb")

   scripts += javascript_include_tag "#{controller.controller_name}.#{controller.action_name}" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.#{controller.action_name}.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.#{controller.action_name}.js.erb")

   if ["new", "create", "edit", "update"].include?(controller.action_name)
      scripts += javascript_include_tag "#{controller.controller_name}.crud" if File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.crud.js") ||  File.exists?("#{Rails.root}/app/assets/javascripts/#{controller_name}.crud.js.erb")
   end

   scripts.html_safe
  end

end
