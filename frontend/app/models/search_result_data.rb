class SearchResultData

  def initialize(search_data)
    @search_data = search_data
    @facet_data = {}

    init_facets
  end

  def init_facets
    @search_data['facets']['facet_fields'].each {|facet_group, facets|
      @facet_data[facet_group] = {}
      facets.each_slice(2).each {|facet_and_count|
        next if facet_and_count[1] === 0

        facet_label = facet_group === "primary_type" ? I18n.t("#{facet_and_count[0]}._html.singular") : facet_and_count[0]

        @facet_data[facet_group][facet_and_count[0]] = {
          :label => facet_label,
          :count => facet_and_count[1],
          :query_string => "{!term f=#{facet_group}}#{facet_and_count[0]}",
          :display_string => "#{I18n.t("search_results.filter.#{facet_group}", :default => facet_group)}: #{facet_label}"
        }
      }
    }
  end

  def [](key)
    @search_data[key]
  end

  def []=(key, value)
    @search_data[key] = value
  end

  def filtered?
    @search_data[:criteria].has_key?("filter[]") and @search_data[:criteria]["filter[]"].length
  end

  def facet_label_for_filter(filter)
    filter_bits = filter.match(/{!term f=(.*)}(.*)/)

    (filter_bits.length === 3) ? 
      @facet_data[filter_bits[1]][filter_bits[2]][:display_string] : filter 
  end

  def facets_for_filter
    facet_data_for_filter = {}.merge(@facet_data)
    facet_data_for_filter.each {|facet_group, facets| 
      facets.delete_if{|facet, facet_map|
        facet_map[:count] === @search_data['total_hits']
      }
    }
    facet_data_for_filter.delete_if {|facet_group, facets| facets.empty?}
    facet_data_for_filter
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

  def sort_filter_for(field)
    return "#{field} asc" if field != sorted_by

    return "" if current_sort_direction === "desc"

    return "#{field} desc"
  end

  def query?
    not @search_data[:criteria]["q"].blank?
  end

  def facet_label_for_query
    "#{I18n.t("search_results.filter.query")}: #{@search_data[:criteria]["q"]}"
  end

end
