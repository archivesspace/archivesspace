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


        if (facet_and_count[0] == "none")
          query = facet_query_string(facet_group, facet_and_count[0])
          if (@search_data[:criteria].has_key?('q'))
            query = @search_data[:criteria]['q'] + ' AND ' + query
          end
          @facet_data[facet_group][facet_and_count[0]] = {
              :label => facet_label_string(facet_group, facet_and_count[0]),
              :count => facet_and_count[1],
              :q => query,
              :display_string => facet_display_string(facet_group, facet_and_count[0])
            }
        else
          @facet_data[facet_group][facet_and_count[0]] = {
              :label => facet_label_string(facet_group, facet_and_count[0]),
              :count => facet_and_count[1],
              :filter_term => facet_query_string(facet_group, facet_and_count[0]),
              :display_string => facet_display_string(facet_group, facet_and_count[0])
            }
        end
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
    if (facet == "none")
      return "-" + facet_group + ":*"
    end
    {facet_group => facet}.to_json
  end

  def [](key)
    @search_data[key]
  end

  def []=(key, value)
    @search_data[key] = value
  end

  def filtered_terms?
    @search_data[:criteria].has_key?("filter_term[]") and @search_data[:criteria]["filter_term[]"].reject {|f| f.empty?}.length > 0
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
      facets.delete_if {|facet, facet_map|
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
    "#{I18n.t("search.#{get_type}.#{facet_group}", :default => I18n.t("search.multi.#{facet_group}", :default => facet_group))}: #{facet_label_string(facet_group, facet)}"
  end

  def facet_label_string(facet_group, facet)
    # Plugins can opt to tell us how facet values should be translated.
    if plugin_key = Plugins.facet_i18n_key(facet_group, facet)
      return I18n.t(plugin_key, :default => facet)
    end

    return I18n.t("search.location.none") if facet == "none"
    return facet.upcase if facet_group == "owner_repo_display_string_u_ssort"
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
      if get_type.include? "subject"
        return I18n.t("enumerations.subject_source.#{facet}", :default => facet)
      else
        return I18n.t("enumerations.name_source.#{facet}", :default => facet)
      end
    end

    if facet_group === "level"
      if get_type.include? "digital_object"
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

    if facet_group === "status"
      return I18n.t("job.status_#{facet}", :default => facet)
    end

    if facet_group === "job_type"
      return I18n.t("job.types.#{facet}", :default => facet)
    end

    if facet_group === "report_type"
      return I18n.t("reports.#{facet}.title", :default => facet)
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

  def get_type
    type = 'multi'
    if @search_data[:type]
      type = @search_data[:type]
    elsif (@search_data[:criteria]["type[]"] || []).length == 1
      type = @search_data[:criteria]["type[]"][0]
    elsif (types = @search_data[:criteria]["type[]"] || []).length == 2
      if types.include?('resource') && types.include?('archival_object')
        type = 'resource'
      elsif types.include?('digital_object') && types.include?('digital_object_component')
        type = 'digital_object'
      end
    elsif terms = @search_data[:criteria]['filter_term[]']
      types = terms.collect { |term| ASUtils.json_parse(term)['primary_type'] }.compact
      type = types[0] if types.length == 1
    end
    type = 'agent' if type.include? 'agent'
    type = 'repositories' if type == 'repository'
    type
  end

  def types
    @search_data[:criteria]["type[]"]
  end

  def sorted?
    @search_data[:criteria]["sort"]
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

  def sorted_by_label(index = 0)
    _sorted_by = sorted_by(index)

    return I18n.t("search_sorting.select") if _sorted_by.nil?

    _sorted_by = 'title_sort' if sorted_by == 'title'

    label = sort_fields[_sorted_by] || I18n.t("search.multi.#{_sorted_by}")
    direction = sorted_by == 'score' ? '' : I18n.t("search_sorting.#{current_sort_direction(index)}")
    "#{label} #{direction}".strip
  end

  def sort_fields
    @sort_fields ||= self.class.BASE_SORT_FIELDS.collect {|f| [f, I18n.t("search.multi.#{f}")]}.to_h
  end

  def add_sort_field(field, label =nil)
    @sort_fields ||= self.class.BASE_SORT_FIELDS.collect {|f| [f, I18n.t("search.multi.#{f}")]}.to_h
    @sort_fields[field] = label || I18n.t("search.multi.#{field}")
  end

  def query?
    not @search_data[:criteria]["q"].blank?
  end

  def facet_label_for_query(query)
    if (query.match(/\-.+\:\*/))
      value = query.tr("-:*", "")
      "#{I18n.t("search.blank_facet_query_fields."+value)+": None"}"
    else
      "#{I18n.t("search.multi.query")}: #{query}"
    end
  end

  def self.BASE_SORT_FIELDS
    %w(create_time user_mtime)
  end

  def self.BASE_FACETS
    ["primary_type", "creators", "subjects", "langcode"] + Plugins.search_facets_for_base
  end

  def self.AGENT_FACETS
    extras = [:agent_person, :agent_family, :agent_corporate_entity, :agent_software]
               .flat_map {|agent_type| Plugins.search_facets_for_type(agent_type)}
    ["primary_type", "source", "rules"] + extras
  end

  def self.ACCESSION_FACETS
    ["subjects", "accession_date_year", "creators"] + Plugins.search_facets_for_type(:accession)
  end

  def self.RESOURCE_FACETS
    ["subjects", "publish", "level", "classification_path", "primary_type", "langcode"] + Plugins.search_facets_for_type(:resource)
  end

  def self.ARCHIVAL_OBJECT_FACETS
    ["subjects", "publish", "level", "classification_path", "primary_type"] + Plugins.search_facets_for_type(:archival_object)
  end

  def self.DIGITAL_OBJECT_FACETS
    ["subjects", "publish", "digital_object_type", "level", "primary_type", "langcode"] + Plugins.search_facets_for_type(:digital_object)
  end

  def self.CONTAINER_PROFILE_FACETS
    ["container_profile_width_u_sstr", "container_profile_height_u_sstr", "container_profile_depth_u_sstr", "container_profile_dimension_units_u_sstr"] + Plugins.search_facets_for_type(:container_profile)
  end

  def self.LOCATION_FACETS
    ["temporary", "owner_repo_display_string_u_ssort", "building", "floor", "room", "area", "location_profile_display_string_u_ssort"] + Plugins.search_facets_for_type(:location)
  end

  def self.SUBJECT_FACETS
    ["source", "first_term_type"] + Plugins.search_facets_for_type(:subject)
  end

  def self.EVENT_FACETS
    ["event_type", "outcome"] + Plugins.search_facets_for_type(:event)
  end

  def self.UNTITLED_TYPES
    ["event"]
  end

  def self.CLASSIFICATION_FACETS
    [] + Plugins.search_facets_for_type(:classification)
  end

  def self.TOP_CONTAINER_FACETS
    []
  end

  def self.ASSESSMENT_FACETS
    ['assessment_record_types', 'assessment_surveyors', 'assessment_review_required', 'assessment_reviewers', 'assessment_completed', 'assessment_inactive', 'assessment_survey_year', 'assessment_sensitive_material'] + Plugins.search_facets_for_type(:assessment)
  end

  def self.JOB_FACETS
    ["status", "job_type", "report_type", "owner"]
  end

  def self.facets_for(record_type)
    if record_type.include? 'agent'
      record_type = 'agent'
    elsif record_type == 'archival_object'
      record_type = 'resource'
    elsif record_type == 'digital_object_component'
      record_type = 'digital_object'
    end
    begin
      self.send("#{record_type.upcase}_FACETS")
    rescue
      self.BASE_FACETS
    end
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
