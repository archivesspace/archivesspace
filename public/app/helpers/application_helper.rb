module ApplicationHelper

  def include_theme_css
    css = ""
    css += stylesheet_link_tag("themes/#{ArchivesSpacePublic::Application.config.public_theme}/bootstrap", :media => "all")
    css += stylesheet_link_tag("themes/#{ArchivesSpacePublic::Application.config.public_theme}/application", :media => "all")
    css.html_safe
  end

  def setup_context(options)
    breadcrumb_trail = options[:breadcrumb_trail] || []

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
    return if value.blank?

    label = content_tag(:dt, label)
    value = content_tag(:dd, value)

    label + value
  end

  def i18n_enum(jsonmodel_type, property, value)
    return if value.blank?

    property_defn = JSONModel(jsonmodel_type).schema["properties"][property]

    return if property_defn.nil?

    if property_defn.has_key? "dynamic_enum"
      enum_key = property_defn["dynamic_enum"]
      #return "enumerations.#{enum_key}.#{value}"
      I18n.t("enumerations.#{enum_key}.#{value}", :default => value)
    else
      I18n.t("#{jsonmodel_type}.#{property}_#{value}", :default => value) 
    end
  end

  def params_for_search(opts = {})
    search_params = {}

    search_params["filter"] = Array(params["filter"]).clone

    if opts["add_filter"]
      search_params["filter"].concat(Array(opts["add_filter"]))
    end

    if opts["remove_filter"]
      search_params["filter"] = search_params["filter"].reject{|f| Array(opts["remove_filter"]).include?(f)}
    end

    search_params["sort"] = opts["sort"] || params["sort"]

    search_params["q"] = opts["q"] || params["q"]

    search_params["type"] = opts["type"] || params["type"]

    # retain any advanced search params
    search_params["advanced"] = opts["advanced"] || params["advanced"]
    (0..2).each do |i|
      search_params["v#{i}"] = params["v#{i}"]
      search_params["f#{i}"] = params["f#{i}"]
      search_params["op#{i}"] = params["op#{i}"]
    end

    search_params
  end

end
