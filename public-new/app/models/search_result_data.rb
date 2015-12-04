class SearchResultData

  def initialize(search_data, repository_data)
    @search_data = search_data
    @facet_data = {}
    @repositories = repository_data
    @filter_label_map = {}

    init_facets
    init_sorts
    init_filter_label_map
    init_highlights
  end

  def init_highlights
    if results?
      @search_data['results'].map! {|result|
        if @search_data['highlighting'].has_key?(result["id"]) && !@search_data['highlighting'][result["id"]].keys.empty?
          result["highlighting"] = @search_data['highlighting'][result["id"]]
        end

        result
      }
    end

    @search_data.delete('highlighting')
  end

  def init_facets
    @search_data['facets']['facet_fields'].each {|facet_group, facets|
      facet_group_code = facet_group.clone
      facet_group = I18n.t("search_results.filter.#{facet_group}", :default => facet_group)
      @facet_data[facet_group] = {}
      facets.each_slice(2).each {|facet_and_count|
        next if facet_and_count[1] === 0

        @facet_data[facet_group][facet_and_count[0]] = {
          :label => facet_label_string(facet_group_code, facet_and_count[0]),
          :count => facet_and_count[1],
          :display_string => facet_display_string(facet_group, facet_and_count[0]),
          :filter_term => {facet_group_code => facet_and_count[0]}.to_json
        }
      }
    }
  end

  def init_sorts
    if sorted?
      @sort_data = @search_data[:criteria]["sort"].split(", ").map {|s|
        matches = s.match(/(\S+)\s(asc|desc)/)
        {:field => matches[1], :direction => matches[2]}
      }
    end
  end

  def init_filter_label_map
    @filter_label_map['q'] = facet_label_for_query if query?

    return unless @search_data[:criteria].has_key?("filter_term[]")
    @search_data[:criteria]["filter_term[]"].each do |filter|
      @filter_label_map[filter] = facet_label_for_filter(filter)
    end
  end


  def [](key)
    @search_data[key]
  end

  def []=(key, value)
    @search_data[key] = value
  end

  def filtered_terms?
    @search_data[:criteria].has_key?("filter_term[]") and @search_data[:criteria]["filter_term[]"].reject{|f| f.empty?}.length > 0
  end

  def facet_label_for_filter(filter, term_map = {})
    filter_json = JSON.parse(filter)
    facet = filter_json.keys[0]
    term = filter_json[facet]

    if term_map.has_key?(term)
      # Use the translation provided in the URL
      facet_display_string(facet, term_map[term])
    elsif @facet_data.has_key?(facet) and @facet_data[facet].has_key?(term)
      @facet_data[facet][term][:display_string]
    else
      facet_display_string(facet, term)
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
    return I18n.t("#{facet}._singular", :default => facet) if facet_group === "primary_type"
    return I18n.t("enumerations.linked_agent_role.#{facet}", :default => facet) if facet_group === "linked_agent_roles"
    return I18n.t("enumerations.name_source.#{facet}", :default => I18n.t("enumerations.subject_source.#{facet}", :default => facet)) if facet_group === "source"

    if facet_group === "repository"
      match = @repositories.select{|repo| repo['uri'] === facet}
      
      if match.empty?
        return facet
      else
        return match.first['name']
      end
    end

    facet
  end

  def facet_query_string(facet_group, facet)
    {facet_group => facet}.to_json
  end

  def results?
    @search_data.has_key?('results') and not @search_data['results'].empty?
  end

  def has_titles?
    if @search_data[:criteria].has_key?("type[]") and (types - self.class.UNTITLED_TYPES).empty?
      false
    else
      true
    end
  end
  
  def length
    @search_data.has_key?('total_hits') ? @search_data['total_hits'] : 0
  end

  def single_type?
    @search_data[:criteria].has_key?("type[]") and @search_data[:criteria]["type[]"].length === 1
  end

  def types
    if @search_data[:criteria].has_key?("type[]") and @search_data[:criteria]["type[]"].length > 0
      @search_data[:criteria]["type[]"].collect{|type| I18n.t("#{type}._plural")}
    else
      []
    end
  end

  def weightable?
    @search_data[:criteria].has_key?("q")
  end

  def sorted?
    @search_data[:criteria].has_key?("sort")
  end

  def sorted_by(index = 0)
    if sorted? && @sort_data[index]
      @sort_data[index][:field]
    else
      nil
    end
  end

  def sorted_by?(field)
    @sort_data.each do |entry|
      return true if entry[:field] == field
    end

    false
  end


  def current_sort_direction(index = 0)
    return "desc" unless sorted?

    @sort_data[index][:direction]
  end

  def sort_fields
    @sort_fields ||= [].concat(self.class.BASE_SORT_FIELDS) 
    single_type? ? @sort_fields : @sort_fields + ['primary_type']
  end

  def sort_filter_for(field, default = "asc")
    return "#{field} #{default}" if field != sorted_by

    return "" if current_sort_direction != default

    return "#{field} #{default === "asc" ? "desc" : "asc"}"
  end


  def sorted_by_label(title_label, index = 0)
    _sorted_by = sorted_by(index)

    if _sorted_by.nil?
      return weightable? ? I18n.t("search_sorting.relevance") : I18n.t("search_sorting.select")
    end

    label = _sorted_by == 'title_sort' ? title_label : I18n.t("search_sorting.#{_sorted_by}")
    direction = I18n.t("search_sorting.#{current_sort_direction(index)}")
    "#{label} #{direction}"
  end

  def query?
    not @search_data[:criteria]["q"].blank?
  end

  def facet_label_for_query
    "#{I18n.t("search_results.filter.query")}: #{@search_data[:criteria]["q"]}"
  end

  def index_results_view_settings
    if @search_data[:criteria].has_key?("type[]") and !@search_data[:criteria]["type[]"].blank?
      self.class.VIEW_SETTINGS[@search_data[:criteria]["type[]"].first]
    else
      nil
    end
  end

  def self.BASE_SORT_FIELDS
    %w(create_time user_mtime)
  end

  def self.UNTITLED_TYPES
    ["event"]
  end

  # currently we don't need all the functionality that is in the staff UI
  # but it is believed we will in the near furture. Commenting out the 
  # additional columns. 
  def self.VIEW_SETTINGS
    {  "agent" => 
          proc {
            title_column_header(I18n.t("agent.name"))
     #       add_column(I18n.t("agnt_name.authority_id"), proc {|record| record['authority_id']}, :sortable => true, :sort_by => "authority_id")
     #       add_column(I18n.t("agent_name.source"), proc {|record| I18n.t("enumerations.name_source.#{record['source']}", :default => record['source']) if record['source']}, :sortable => true, :sort_by => "source")
     #       add_column(I18n.t("agent_name.rules"), proc {|record| I18n.t("enumerations.name_rule.#{record['rules']}", :default => record['rules']) if record['rules']}, :sortable => true, :sort_by => "rules")
          },
        "subject" => 
          proc { title_column_header(I18n.t('subject.terms')) }
    }
  end
end
