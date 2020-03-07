class SearchResultData

  def initialize(search_data)
    @search_data = search_data
    @facet_data = {}

    self.class.run_result_hooks(search_data)
    init_facets
    init_sorts
  end


  def init_facets
    @search_data['facets']['facet_fields'].each {|facet_group, facets|
      @facet_data[facet_group] = {}
      facets.each_slice(2).each {|facet_and_count|
        next if facet_and_count[1] === 0

        @facet_data[facet_group][facet_and_count[0]] = {
          :label => facet_label_string(facet_group, facet_and_count[0]),
          :count => facet_and_count[1],
          :filter_term => facet_query_string(facet_group, facet_and_count[0]),
          :display_string => facet_display_string(facet_group, facet_and_count[0])
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


  def facet_query_string(facet_group, facet)
    {facet_group => facet}.to_json
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

  def facet_label_for_filter(filter)
    filter_json = ASUtils.json_parse(filter)
    facet = filter_json.keys[0]
    term = filter_json[facet]

    if @facet_data.has_key?(facet) and @facet_data[facet].has_key?(term)
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
    facet_data_for_filter.each do |facet_group, facets|
      facet_data_for_filter[facet_group] = sort_facets(facet_group, facets)
    end
    facet_data_for_filter
  end

  def sort_facets(facet_group, facets)
    case facet_group
    when 'accession_date_year'
      f = facets.sort { |a, b| (b[0].to_i <=> a[0].to_i) * (AppConfig[:sort_accession_date_filter_asc] ? -1 : 1) }.to_h
      f['9999'][:label] = I18n.t("accession.accession_date_unknown") if f['9999']
      f
    else
      facets
    end
  end

  def facet_display_string(facet_group, facet)
    "#{I18n.t("search_results.filter.#{facet_group}", :default => facet_group)}: #{facet_label_string(facet_group, facet)}"
  end

  def facet_label_string(facet_group, facet)
    return I18n.t("#{facet}._singular", :default => I18n.t("plugins.#{facet}._singular", :default => facet)) if facet_group === "primary_type"
    return I18n.t("enumerations.name_source.#{facet}", :default => I18n.t("enumerations.subject_source.#{facet}", :default => facet)) if facet_group === "source"
    return I18n.t("enumerations.name_rule.#{facet}", :default => facet) if facet_group === "rules"
    return I18n.t("boolean.#{facet.to_s}", :default => facet) if facet_group === "publish"
    return I18n.t("enumerations.digital_object_digital_object_type.#{facet.to_s}", :default => facet) if facet_group === "digital_object_type"
    return I18n.t("enumerations.location_temporary.#{facet.to_s}", :default => facet) if facet_group === "temporary"
    return I18n.t("enumerations.event_event_type.#{facet.to_s}", :default => facet) if facet_group === "event_type"
    return I18n.t("enumerations.event_outcome.#{facet.to_s}", :default => facet) if facet_group === "outcome"
    return I18n.t("enumerations.subject_term_type.#{facet.to_s}", :default => facet) if facet_group === "first_term_type"

    return I18n.t("enumerations.language_iso639_2.#{facet}", :default => facet) if facet_group === "langcode"

    if facet_group === "source"
      if single_type? and types[0] === "subject"
        return I18n.t("enumerations.subject_source.#{facet}", :default => facet)
      else
        return I18n.t("enumerations.name_source.#{facet}", :default => facet)
      end
    end

    if facet_group === "level"
        if single_type? and types[0] === "digital_object"
          return I18n.t("enumerations.digital_object_level.#{facet.to_s}", :default => facet)
        else
          return I18n.t("enumerations.archival_record_level.#{facet.to_s}", :default => facet)
        end
    end

    # labels for collection management groups
    return I18n.t("#{facet}._singular", :default => facet) if facet_group === "parent_type"
    return I18n.t("enumerations.collection_management_processing_priority.#{facet}", :default => facet) if facet_group === "processing_priority"
    return I18n.t("enumerations.collection_management_processing_status.#{facet}", :default => facet) if facet_group === "processing_status"

    if facet_group === "classification_path"
      return ClassificationHelper.format_classification(ASUtils.json_parse(facet))
    end

    if facet_group === "assessment_review_required"
      return I18n.t("assessment._frontend.assessment_review_required.#{facet}_value")
    end

    if facet_group === "assessment_sensitive_material"
      return I18n.t("assessment._frontend.assessment_sensitive_material.#{facet}_value")
    end

    if facet_group === "assessment_inactive"
      return I18n.t("assessment._frontend.assessment_inactive.#{facet}_value")
    end

    if facet_group === "assessment_record_types"
      return I18n.t("#{facet}._singular", :default => facet)
    end

    if facet_group === "assessment_completed"
      return I18n.t("assessment._frontend.assessment_completed.#{facet}_value")
    end

    facet
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

  def single_type?
    if @search_data[:criteria].has_key?("type[]")
      @search_data[:criteria]["type[]"].length === 1
    elsif @search_data[:type]
      true
    else
      false
    end
  end

  def types
    @search_data[:criteria]["type[]"]
  end

  def sort_fields
    @sort_fields ||= [].concat(self.class.BASE_SORT_FIELDS)

    single_type? ? @sort_fields : @sort_fields + ['primary_type']
  end

  def sorted?
    @search_data[:criteria].has_key?("sort")
  end

  def weightable?
    @search_data[:criteria].has_key?("q")
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

  def self.BASE_SORT_FIELDS
    %w(create_time user_mtime)
  end

  def self.BASE_FACETS
    ["primary_type","creators","subjects","langcode"]
  end

  def self.AGENT_FACETS
    ["primary_type", "source", "rules"]
  end

  def self.ACCESSION_FACETS
    ["subjects", "accession_date_year", "creators"]
  end

  def self.RESOURCE_FACETS
    ["subjects", "publish", "level", "classification_path", "primary_type", "langcode"]
  end

  def self.DIGITAL_OBJECT_FACETS
    ["subjects", "publish", "digital_object_type", "level", "primary_type", "langcode"]
  end

  def self.CONTAINER_PROFILE_FACETS
    ["container_profile_width_u_sstr", "container_profile_height_u_sstr", "container_profile_depth_u_sstr", "container_profile_dimension_units_u_sstr"]
  end

  def self.LOCATION_FACETS
    ["temporary", "building", "floor", "room", "area", "location_profile_display_string_u_ssort"]
  end

  def self.SUBJECT_FACETS
    ["source", "first_term_type"]
  end

  def self.EVENT_FACETS
    ["event_type", "outcome"]
  end

  def self.UNTITLED_TYPES
    ["event"]
  end

  def self.CLASSIFICATION_FACETS
    []
  end

  def self.ASSESSMENT_FACETS
    ['assessment_record_types', 'assessment_surveyors', 'assessment_review_required', 'assessment_reviewers', 'assessment_completed', 'assessment_inactive', 'assessment_survey_year', 'assessment_sensitive_material']
  end


  def self.add_result_hook(&block)
    @result_hooks ||= []
    @result_hooks << block
  end


  def self.run_result_hooks(results)
    @result_hooks ||= []
    Array(@result_hooks).each do |hook|
      hook.call(results)
    end
  end


  # Search result mangling for classification paths + titles
  self.add_result_hook do |results|
    results['results'].each do |result|
      if result['primary_type'] =~ /^classification/ && result.has_key?('classification_path')
        path = ASUtils.json_parse(result['classification_path'])
        result['title'] = ClassificationHelper.format_classification(path)
      end
    end
  end

end
