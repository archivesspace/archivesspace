class SearchResultData

  def initialize(search_data)
    @search_data = search_data
    @facet_data = {}

    clean_search_data
    init_facets
  end

  def init_facets
    @search_data['facets']['facet_fields'].each {|facet_group, facets|
      @facet_data[facet_group] = {}
      facets.each_slice(2).each {|facet_and_count|
        next if facet_and_count[1] === 0

        @facet_data[facet_group][facet_and_count[0]] = {
          :label => facet_label_string(facet_group, facet_and_count[0]),
          :count => facet_and_count[1],
          :query_string => "{!term f=#{facet_group}}#{facet_and_count[0]}",
          :display_string => facet_display_string(facet_group, facet_and_count[0])
        }
      }
    }
  end

  def clean_search_data
    if @search_data[:criteria].has_key?("filter[]")
      @search_data[:criteria]["filter[]"] = @search_data[:criteria]["filter[]"].reject{|f| f.empty?}
    end
  end

  def [](key)
    @search_data[key]
  end

  def []=(key, value)
    @search_data[key] = value
  end

  def filtered?
    @search_data[:criteria].has_key?("filter[]") and @search_data[:criteria]["filter[]"].reject{|f| f.empty?}.length > 0
  end

  def facet_label_for_filter(filter)
    filter_bits = filter.match(/{!term f=(.*)}(.*)/)

    return filter if (filter_bits.length != 3)

    if @facet_data.has_key?(filter_bits[1]) and @facet_data[filter_bits[1]].has_key?([filter_bits[2]])
      @facet_data[filter_bits[1]][filter_bits[2]][:display_string]
    else
      facet_display_string(filter_bits[1], filter_bits[2])
    end 
  end

  def facets_for_filter
    facet_data_for_filter = @facet_data.clone
    facet_data_for_filter.each {|facet_group, facets| 
      facets.delete_if{|facet, facet_map|
        facet_map[:count] === @search_data['total_hits']
      }
    }
    facet_data_for_filter.delete_if {|facet_group, facets| facets.empty?}
    facet_data_for_filter
  end

  def facet_display_string(facet_group, facet)
    "#{I18n.t("search_results.filter.#{facet_group}", :default => facet_group)}: #{facet_label_string(facet_group, facet)}"
  end

  def facet_label_string(facet_group, facet)
    return I18n.t("#{facet}._html.singular", :default => facet) if facet_group === "primary_type"
    return I18n.t("enumerations.name_source.#{facet}", :default => facet) if facet_group === "source"
    return I18n.t("enumerations.name_rule.#{facet}", :default => facet) if facet_group === "rules"
    return I18n.t("boolean.#{facet.to_s}", :default => facet) if facet_group === "publish"

    # labels for collection management groups
    return I18n.t("#{facet}._html.singular", :default => facet) if facet_group === "parent_type"
    return I18n.t("enumerations.collection_management_processing_priority.#{facet}", :default => facet) if facet_group === "processing_priority"
    return I18n.t("enumerations.collection_management_processing_status.#{facet}", :default => facet) if facet_group === "processing_status"
    facet
  end

  def results?
    @search_data.has_key?('results') and not @search_data['results'].empty?
  end

  def single_type?
    @search_data[:criteria].has_key?("type[]") and @search_data[:criteria]["type[]"].length > 1 or not @search_data[:criteria].has_key?("type[]")
  end

  def sorted?
    @search_data[:criteria].has_key?("sort")
  end

  def sorted_by
    return nil if not sorted?

    matches = @search_data[:criteria]["sort"].match(/(\S*[^\s])\s(asc|desc)?/)

    return matches[1] if matches.length > 1

    @search_data[:criteria]["sort"]
  end

  def current_sort_direction
    return "desc" if not sorted?

    matches = @search_data[:criteria]["sort"].match(/(\S*[^\s])\s(asc|desc)?/)

    return matches[2] if matches.length > 1

    "desc"
  end

  def sort_filter_for(field, default = "asc")
    return "#{field} #{default}" if field != sorted_by

    return "" if current_sort_direction != default

    return "#{field} #{default === "asc" ? "desc" : "asc"}"
  end

  def sorted_by_label
    _sorted_by = sorted_by

    return I18n.t("search_sorting.relevance") if _sorted_by.nil?

    "#{I18n.t("search_sorting.#{_sorted_by}")} (#{I18n.t("search_sorting.#{current_sort_direction}")})"
  end

  def query?
    not @search_data[:criteria]["q"].blank?
  end

  def facet_label_for_query
    "#{I18n.t("search_results.filter.query")}: #{@search_data[:criteria]["q"]}"
  end

end
