module ApplicationHelper

  def include_theme_css
    css = ""
    css += stylesheet_link_tag("themes/#{ArchivesSpacePublic::Application.config.public_theme}/bootstrap", :media => "all")
    css += stylesheet_link_tag("themes/#{ArchivesSpacePublic::Application.config.public_theme}/application", :media => "all")
    css.html_safe
  end

  def set_title(title)
    @title = title
  end

  def icon_for(type)
    "<span class='icon-#{type}' title='#{I18n.t("#{type}._singular")}'></span>".html_safe
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

    search_params["filter_term"] = Array(opts["filter_term"] || params["filter_term"]).clone
    search_params["filter_term"].concat(Array(opts["add_filter_term"])) if opts["add_filter_term"]
    search_params["filter_term"] = search_params["filter_term"].reject{|f| Array(opts["remove_filter_term"]).include?(f)} if opts["remove_filter_term"]

    search_params["sort"] = opts["sort"] || params["sort"]

    search_params["q"] = opts["q"] || params["q"]

    if opts["type"] && opts["type"].kind_of?(Array)
      search_params["type"] = opts["type"]
    else
      search_params["type"] = opts["type"] || params["type"]
    end

    search_params["term_map"] = params["term_map"]

    # retain any advanced search params
    advanced = (opts["advanced"] || params["advanced"])
    search_params["advanced"] = advanced.blank? || advanced === 'false' ? false : true
    (0..2).each do |i|
      search_params["v#{i}"] = params["v#{i}"]
      search_params["f#{i}"] = params["f#{i}"]
      search_params["op#{i}"] = params["op#{i}"]
    end

    search_params.reject{|k,v| k.blank? or v.blank?}
  end

  def set_title_for_search
    title =  I18n.t("actions.search")

    if @search_data
      if params[:type] && !@search_data.types.blank?
        title = "#{I18n.t("search_results.searching")} #{@search_data.types.join(", ")}"
      end

      facets_to_display = []

      if @search_data.query?
        facets_to_display << @search_data.facet_label_for_query
      end

      if @search_data.filtered_terms?
        facets_to_display << @search_data[:criteria]["filter_term[]"].collect{|filter_term| @search_data.facet_label_for_filter(filter_term)}
      end

      if facets_to_display.length > 0
        title += " | #{facets_to_display.join(", ")}"
      end
    end

    set_title(title)
  end

end
