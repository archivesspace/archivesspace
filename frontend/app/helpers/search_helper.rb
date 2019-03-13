module SearchHelper

  IDENTIFIER_FOR_SEARCH_RESULT_LOOKUP = {
    "accession"                => "identifier",
    "agent_corporate_entity"   => "authority_id",
    "agent_family"             => "authority_id",
    "agent_person"             => "authority_id",
    "agent_software"           => "authority_id",
    "archival_object"          => "component_id",
    "assessment"               => "assessment_id",
    "classification"           => "identifier",
    "classification_term"      => "identifier",
    "digital_object"           => "digital_object_id",
    "digital_object_component" => "component_id",
    "event"                    => "refid",
    "repository"               => "repo_code",
    "resource"                 => "identifier",
    "subject"                  => "authority_id",
  }

  def build_search_params(opts = {})
    search_params = {}

    search_params["filter_term"] = Array(opts["filter_term"] || params["filter_term"]).clone
    search_params["filter_term"].concat(Array(opts["add_filter_term"])) if opts["add_filter_term"]
    search_params["filter_term"] = search_params["filter_term"].reject{|f| Array(opts["remove_filter_term"]).include?(f)} if opts["remove_filter_term"]

    if params["multiplicity"]
      search_params["multiplicity"] = params["multiplicity"] 
    end

    sort = (opts["sort"] || params["sort"])

    # if the browse list was sorted by default
    if sort.nil? && !@search_data.nil? && @search_data.sorted?
      sort = @search_data[:criteria]["sort"]
    end

    if sort
      sort = sort.split(', ')
      sort[1] = opts["sort2"] if opts["sort2"]
      search_params["sort"] = sort.uniq.join(', ')
    end

    if (opts["format"] || params["format"]).blank?
      search_params.delete("format")
    else
      search_params["format"] =  opts["format"] || params["format"]
    end

    search_params["linker"] = opts["linker"] || params["linker"] || false
    search_params["type"] = opts["type"] || params["type"]
    search_params["facets"] = opts["facets"] || params["facets"]
    search_params["exclude"] = opts["exclude"] || params["exclude"]
    search_params["listing_only"] = true if params["listing_only"]
    search_params["include_components"] = opts.has_key?("include_components") ? opts["include_components"] : params["include_components"]

    search_params["q"] = opts["q"] || params["q"]

    # retain advanced search params
    if params["advanced"]
      search_params["advanced"] = params["advanced"]
      params.keys.each do |param_key|
        ["op", "f", "v", "dop", "t", "top"].each do |adv_search_prefix|
          if param_key =~ /^#{adv_search_prefix}\d+/
            search_params[param_key] = params[param_key]
          end
        end
      end
    end

    search_params.reject{|k,v| k.blank? or v.blank?}
  end

  def allow_multiselect?
    @allow_multiselect ||= false
  end

  def can_edit_search_result?(record)
    return user_can?('update_container_record', record['id']) if record['primary_type'] === "top_container"
    return user_can?('manage_repository', record['id']) if record['primary_type'] === "repository"
    return user_can?('update_location_record') if record['primary_type'] === "location"
    return user_can?('update_subject_record') if record['primary_type'] === "subject"
    return user_can?('update_classification_record') if ["classification", "classification_term"].include?(record['primary_type'])
    return user_can?('update_agent_record') if Array(record['types']).include?("agent")

    return user_can?('update_accession_record') if record['primary_type'] === "accession"
    return user_can?('update_resource_record') if ["resource", "archival_object"].include?(record['primary_type'])
    return user_can?('update_digital_object_record') if ["digital_object", "digital_object_component"].include?(record['primary_type'])
    return user_can?('update_assessment_record') if record['primary_type'] === "assessment"
  end

  def default_block(opts)
    
  end


  def add_column(label, opts = {}, block = nil)
    block ||= if opts[:template]
      proc do |record|
        render_aspace_partial :partial => opts[:template], :locals => {:record => record}
      end
    else
      proc do |record|
        v = record[opts[:field]] || ASUtils.json_parse(record['json'])[opts[:field]]
        if opts[:multi]
          content_tag('ul', :style => 'padding-left: 20px;') {
            Array(v).collect { |i|
              content_tag('li',
                I18n.t("enumerations.#{opts[:enum_locale_key]}.#{i}", :default => i.to_s))
            }.join.html_safe
          }
        else
          I18n.t("enumerations.#{opts[:enum_locale_key]}.#{v}", :default => v.to_s)
        end
      end
    end

    opts[:sort_by] ||= (opts[:field] == 'title') ? 'title_sort' : opts[:field]

    @columns ||= []

    if opts[:sortable] && opts[:sort_by]
      @search_data.add_sort_field(opts[:sort_by], label)
    end

    col = SearchColumn.new(label, block, opts, @search_data)
    @columns.push(col)
  end

  def add_multiselect_column
    @allow_multiselect = true
    add_column(sr_only('Selected?'), :template => 'shared/multiselect',
      :class => 'multiselect-column')
  end

  def add_audit_info_column
    add_column(sr_only('Audit information'), {},
      proc { |record| display_audit_info(record, :format => 'compact') })
    @search_data.add_sort_field 'create_time'
    @search_data.add_sort_field 'user_mtime'
  end

  def add_user_pref_columns(model, enum_locales = {})
    (1..5).to_a.each do |n|
      prop = user_prefs["#{model}_browse_column_#{n}"]
      if prop && prop != 'no_value'
        enum_locale_key = enum_locales[prop] || "#{model}_#{prop}"
        add_column(I18n.t("#{model}.#{prop}"), :sortable => true, :field => prop,
          :enum_locale_key => enum_locale_key, :model => model)
      end
    end
  end

  def add_actions_column
    add_column(sr_only('Actions'), :template => 'shared/actions',
      :class => 'actions table-record-actions')
  end

  def add_context_column(label = I18n.t("search_results.context"))
    add_column(label, :template => 'search/context')
  end

  def add_record_type_column
    add_column(I18n.t("search_results.result_type"), {:sortable => true, :field => 'primary_type'},
      proc { |record|
        I18n.t("#{record["primary_type"]}._singular",
          :default => I18n.t("plugins.#{record["primary_type"]}._singular"))
      })
  end

  def add_linker_column
    add_column(sr_only('Linker'),
      proc { |record|
        if params[:multiplicity] === 'many'
          check_box_tag "linker-item", record["id"], false, :"data-object" => record.to_json
        else
          radio_button_tag "linker-item", record["id"], false, :"data-object" => record.to_json
        end
      })
  end

  def add_title_column(label = I18n.t("search_results.result_title"))
    add_column(label, :template => 'search/title', :sortable => true, :field => 'title')
  end

  def sr_only(text)
    ('<span class="sr-only">' + text + '</span>').html_safe
  end

  def get_columns
    return @columns if @columns

    browsing = !(request.path =~ /\/(advanced_)*search/)

    add_linker_column if params[:linker]==='true'

    case type = @search_data.get_type
    when 'accession'
      add_multiselect_column if user_can?("delete_archival_record") && browsing
      add_title_column I18n.t("accession.title")
      add_user_pref_columns('accession')
      add_audit_info_column
    when 'resource', 'archival_object'
      add_multiselect_column if user_can?('delete_archival_record') && browsing
      add_record_type_column if params[:include_components]
      add_title_column I18n.t('resource.title')
      add_context_column if params[:include_components] || type == 'archival_object'
      add_user_pref_columns('resource')
      add_audit_info_column
    when 'digital_object', 'digital_object_component'
      add_multiselect_column if user_can?('delete_archival_record') && browsing
      add_record_type_column if params[:include_components]
      add_title_column I18n.t('digital_object.title')
      add_context_column if params[:include_components] || type == 'digital_object_component'
      add_user_pref_columns('digital_object')
      add_audit_info_column
    when 'assessment'
      add_multiselect_column if user_can?('delete_assessment_record') && browsing
      add_column(I18n.t("assessment.id"), :sortable => true, :field => 'assessment_id',
        :class => 'col-sm-1')
      add_column(I18n.t("assessment.records"), :template => 'assessments/search_result_records_cell',
        :class => 'col-sm-6')
      add_column(I18n.t("assessment.surveyed_by"),
        :template => 'assessments/search_result_surveyed_by_cell', :class => 'col-sm-2')
      add_column(I18n.t("assessment.survey_end"),
        {:sortable => true, :field => "assessment_survey_end", :class => 'col-sm-2'},
        proc {|record| 
          record['assessment_survey_end'] ? Date.parse(record['assessment_survey_end']) : ''
        })
      add_user_pref_columns("assessment")
      add_audit_info_column
    when 'subjects'
      add_multiselect_column if user_can?("delete_subject_record") && browsing
      add_title_column I18n.t("subject.terms")
      add_audit_info_column
    when 'agent', 'agent_person', 'agent_software', 'agent_family', 'agent_corporate_entity'
      add_multiselect_column if user_can?("delete_agent_record")
      add_record_type_column if type == 'agent'
      add_title_column I18n.t('agent.name')
      add_column(I18n.t("agent_name.authority_id"), :sortable => true, :field => "authority_id")
      add_column(I18n.t("agent_name.source"), :sortable => true, :field => "source",
        :enum_locale_key => 'name_source')
      add_column(I18n.t("agent_name.rules"), :sortable => true, :field => "rules",
        :enum_locale_key => 'name_rule')
      add_audit_info_column
    when 'location'
      add_multiselect_column if user_can?("update_location_record")
      add_title_column I18n.t('location.title')
      %w(building floor room area).each do |place|
        add_column(I18n.t("location.#{place}"), :sortable => true, :field => place)
      end
      add_column(I18n.t("location_profile._singular"), :sortable => true,
        :field => "location_profile_display_string_u_ssort")
      add_column("#{current_repo['repo_code']} #{I18n.t("location.holdings")}",
        :template => 'locations/location_holdings')
      add_audit_info_column
    when 'event'
      add_column(I18n.t("event.event_type"), :sortable => true, :field => "event_type",
        :enum_locale_key => 'event_event_type')
      add_column(I18n.t("event.outcome"), :sortable => true, :field => "outcome",
        :enum_locale_key => 'event_outcome')
      add_column(I18n.t("linked_agent._plural"), {}, proc {|record|
        event = ASUtils.json_parse(record['json'])
        event['linked_agents'].map{|link|
          content_tag("div", "#{I18n.t("enumerations.linked_agent_event_roles.#{link['role']}", :default => link['role'])}: #{link['_resolved']['title']}")
        }.join.html_safe
      })
      add_column(I18n.t("linked_record._plural"), {}, proc {|record|
        event = ASUtils.json_parse(record['json'])
        event['linked_records'].map{|link|
          content_tag("div", "#{I18n.t("enumerations.linked_event_archival_record_roles.#{link['role']}", :default => link['role'])}: #{link['_resolved']['title']}")
        }.join.html_safe
      })
      add_audit_info_column
    when 'collection_management'
      add_title_column
      add_column(I18n.t("search_results.result_type"), {:sortable => true, :field => "parent_id"},
        proc {|record| I18n.t("#{JSONModel.parse_reference(record['parent_id'])[:type]}._singular")})
      add_column(I18n.t("collection_management.processing_priority"), :sortable => true,
        :field => "processing_priority",
        :enum_locale_key => 'collection_management_processing_priority')
      add_column(I18n.t("collection_management.processing_status"), :sortable => true,
        :field => "processing_status", :enum_locale_key => 'collection_management_processing_status')
      add_column(I18n.t("collection_management.processing_hours_total_short"), :sortable => true,
        :field => "processing_hours_total")
      add_audit_info_column
    when 'classification', 'classification_term'
      add_multiselect_column if user_can?("delete_classification_record") && browsing
      add_title_column I18n.t('classification.title')
      add_audit_info_column
    when 'location_profile', 'container_profile'
      add_title_column
      add_audit_info_column
    when 'repositories'
      add_title_column
      add_column(I18n.t("repository.publish"), {}, proc {|repo| I18n.t("boolean.#{repo['publish']}")})
      add_audit_info_column
    when 'top_container'
      # add_column('', {}, proc {|record| debug(record)})
      add_context_column I18n.t("top_container._frontend.bulk_operations.collection_singular")
      add_column(I18n.t("top_container.type"), :field => 'type', :sortable => true,
        :enum_locale_key => 'container_type')
      add_column(I18n.t("top_container.indicator"), :field => 'indicator', :sortable => true)
      add_column(I18n.t("top_container.barcode"), :field => 'barcode', :sortable => true)
      add_column(I18n.t("top_container._frontend.bulk_operations.current_location"),
        :field => 'location_display_string_u_sstr', :multi => true)
      add_audit_info_column
    else
      add_record_type_column
      add_title_column
      add_context_column
      add_column(I18n.t("search_results.result_identifier"), :sortable => true, :field => 'identifier')
      add_audit_info_column
    end
    add_actions_column if !params[:linker] || params[:linker] === 'false'
    @columns
  end

  def deleted(record)
    params.has_key?("deleted_uri") and Array(params["deleted_uri"]).include?(record["id"])
  end

  def get_ancestor_title(field)
    if !JSONModel::HTTP.get_json(field).nil?
      if field.include?('resources') || field.include?('digital_objects')
        clean_mixed_content(JSONModel::HTTP.get_json(field)['title'])
      else
        clean_mixed_content(JSONModel::HTTP.get_json(field)['display_string'])
      end
    end
  end

  def context_separator(result)
    if result['ancestors'] || result['linked_instance_uris']
      @separator = '>'
    else
      @separator = '<br />'.html_safe
    end
  end

  def context_ancestor(result)
    case
    when result['ancestors']
      ancestors = result['ancestors']
    when result['linked_instance_uris']
      ancestors = result['linked_instance_uris']
    when result['linked_record_uris']
      ancestors = result['linked_record_uris']
    when result['primary_type'] == 'top_container'
      ancestors = Array(result['collection_uri_u_sstr'])
    when result['primary_type'] == 'digital_object_component'
      ancestors = result['digital_object'].split
    else
      ancestors = ['']
    end
  end

  


  class SearchColumn

    def initialize(label, value_block, opts, search_data)
      @label = label
      @value_block = value_block
      @classes = "col "
      @classes << opts[:class] if opts[:class]
      @sortable = opts[:sortable] || false
      @sort_by = opts[:sort_by] || ""
      @search_data = search_data
    end


    def value_for(record)
      @value_block.call(record)
    end


    def label
      @label
    end


    def sortable?
      @sortable
    end


    def sort_by
      @sort_by
    end


    def class
      @classes << " sortable" if sortable?
      @classes << " sort-#{@search_data.current_sort_direction}" if sortable? && @search_data.sorted_by === @sort_by
      @classes
    end

  end
end
