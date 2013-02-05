module ApplicationHelper

  def include_theme_css
    css = ""
    css += stylesheet_link_tag("themes/#{ArchivesSpacePublic::Application.config.public_theme}/bootstrap", :media => "all")
    css += stylesheet_link_tag("themes/#{ArchivesSpacePublic::Application.config.public_theme}/application", :media => "all")
    css.html_safe
  end

  def setup_context(options)

    breadcrumb_trail = []

    if options.has_key? :object
      object = options[:object]

      type = options[:type] || object["jsonmodel_type"]
      controller = options[:controller] || type.to_s.pluralize

      title = options[:title] || object["title"] || object["username"]

      breadcrumb_trail.push(["#{I18n.t("#{controller.to_s.singularize}._html.plural")}", {:controller => controller, :action => :index}])

      if object.id
        breadcrumb_trail.push([title, {:controller => controller, :action => :show}])
        breadcrumb_trail.last.last[:id] = object.id unless object['username']

        if ["edit", "update"].include? action_name
          breadcrumb_trail.push([I18n.t("actions.edit")])
          set_title("#{I18n.t("#{type}._html.plural")} | #{title} | #{I18n.t("actions.edit")}")
        else
          set_title("#{I18n.t("#{type}._html.plural")} | #{title}")
        end
      else # new object
        breadcrumb_trail.push([options[:title] || "#{I18n.t("actions.new_prefix")} #{I18n.t("#{type}._html.singular")}"])
        set_title("#{I18n.t("#{controller.to_s.singularize}._html.plural")} | #{options[:title] || I18n.t("actions.new_prefix")}")
      end
    elsif options.has_key? :title
      set_title(options[:title])
      breadcrumb_trail.push([options[:title]])
    end

    render(:partial =>"shared/breadcrumb", :layout => false , :locals => { :trail => breadcrumb_trail }).to_s if options[:suppress_breadcrumb] != true
  end

  def set_title(title)
    @title = title
  end

  def icon_for(type)
    "<span class='icon-#{type}' title='#{I18n.t("#{type}._html.singular")}'></span>".html_safe
  end

  def label_and_value(label, value)
    return if value.nil?

    label = content_tag(:div, label, :class => "control-label")
    value = content_tag(:div, value, :class => "controls label-only")
    content_tag(:div, label + value, :class => "control-group")
  end

end
