require 'search_result_data'
require 'advanced_query_builder'

class Search

  def self.for_type(repo_id, type, criteria)
    criteria['type[]'] = Array(type)

    Search.all(repo_id, criteria)
  end

  # :context_criteria - added to criteria for building the query, but hidden from user
  # :sorting - ignore repo preferences and use provided sort for results (i.e. for typeaheads)
  def self.all(repo_id, criteria, context_criteria = {})
    context_criteria.each do |k, v|
      if v.is_a? Array
        criteria[k] ||= []
        criteria[k] += v
      else
        criteria[k] = v
      end
    end

    build_filters(criteria)
    criteria["page"] = 1 if not criteria.has_key?("page")
    criteria["sort"] ||= sort(criteria["type[]"] || (criteria["filter_term[]"] || []).collect { |term| ASUtils.json_parse(term)['primary_type'] }.compact)

    search_data = JSONModel::HTTP::get_json("/repositories/#{repo_id}/search", criteria)

    #If the criteria contains a 'blank_facet_query_fields' field,
    #we want to add a facet to filter on items WITHOUT an entry in the facet
    if (criteria.has_key?("blank_facet_query_fields"))
      blank_facet_query = ""
      criteria["blank_facet_query_fields"].each {|query_field|
        blank_facet_query = "-" + query_field + ":*"
        sub_criteria = criteria.clone
        if (sub_criteria.has_key?("q") && sub_criteria["q"] != blank_facet_query)
          sub_criteria["q"] = criteria["q"] + " AND " + blank_facet_query
        else
          sub_criteria["q"] = blank_facet_query
        end

        search_data_with_blank_facet = JSONModel::HTTP::get_json("/repositories/#{repo_id}/search", sub_criteria)
        if (!search_data["facets"]["facet_fields"].has_key?(query_field))
          search_data["facets"]["facet_fields"][query_field] = ["none", search_data_with_blank_facet["total_hits"]]
        else
          search_data["facets"]["facet_fields"][query_field] << "none"
          search_data["facets"]["facet_fields"][query_field] << search_data_with_blank_facet["total_hits"]
        end
      }

    end

    SearchResultData.new(search_data, criteria, context_criteria)
  end


  def self.global(criteria, type)
    build_filters(criteria)

    criteria["page"] = 1 if not criteria.has_key?("page")
    criteria["sort"] ||= default_sort_for_type(type)

    search_data = JSONModel::HTTP::get_json("/search/#{type}", criteria)
    search_data[:type] = type
    SearchResultData.new(search_data, criteria)
  end

  # Helper to get the default sort string for a given record type, honoring preferences
  # - type [String] Record type
  def self.default_sort_for_type(type)
    normalized_type =
      if type.include?('agent')
        'agent'
      elsif type == 'classification_term'
        'classification'
      elsif type == 'repository'
        'repositories'
      else
        type
      end

    repo = JSONModel.repository
    prefs = if repo
              JSONModel::HTTP::get_json("/repositories/#{repo}/current_preferences")["defaults"]
            else
              JSONModel::HTTP::get_json("/current_global_preferences")["defaults"]
            end

    configured_col = prefs["#{normalized_type}_sort_column"].presence || 'score'
    derived_sort_col = SearchAndBrowseColumnConfig.columns.dig(normalized_type, configured_col, :sort_by)
    sort_col = derived_sort_col || configured_col

    direction = prefs["#{normalized_type}_sort_direction"]
    direction = %w[asc desc].include?(direction) ? direction : 'desc'

    "#{sort_col} #{direction}"
  end

  private

  def self.sort(types)
    types ||= []
    type = if types.length > 0 && types.all? { |t| t.include? 'agent' }
             'agent'
           elsif types.length == 1
             types[0]
           elsif types.length == 2 && types.include?('resource') && types.include?('archival_object')
             'resource'
           elsif types.length == 2 && types.include?('digital_object') && types.include?('digital_object_component')
             'digital_object'
           else
             'multi'
           end

    default_sort_for_type(type)
  end

  def self.build_filters(criteria)
    queries = AdvancedQueryBuilder.new

    Array(criteria['filter_term[]']).each do |json_filter|
      filter = ASUtils.json_parse(json_filter)
      queries.and(filter.keys[0], filter.values[0])
    end

    Array(criteria['static_filter_term[]']).each do |json_filter|
      filter = ASUtils.json_parse(json_filter)
      queries.and(filter.keys[0], filter.values[0])
    end

    new_filter = queries.empty? ? {} : queries.build

    if criteria['filter']
      # Combine our new filter with any existing ones
      existing_filter = ASUtils.json_parse(criteria['filter'])
      subqueries = [existing_filter['query']]
      subqueries << new_filter['query'] if new_filter['query']

      new_filter['query'] = JSONModel(:boolean_query)
                              .from_hash({
                                           :jsonmodel_type => 'boolean_query',
                                           :op => 'AND',
                                           :subqueries => subqueries
                                         })
    end

    criteria['filter'] = new_filter['query'] ? new_filter.to_json : nil
    criteria
  end

end
