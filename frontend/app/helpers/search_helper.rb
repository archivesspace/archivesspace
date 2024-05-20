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

  def identifier_for_search_result(result)
    identifier = IDENTIFIER_FOR_SEARCH_RESULT_LOOKUP.fetch(result["primary_type"], "")
    unless identifier.empty?
      if result.has_key? identifier
        identifier = result[identifier]
      else
        json       = ASUtils.json_parse(result["json"])
        identifier = json.fetch(identifier, "")
      end
    end
    identifier.to_s.html_safe
  end

  def build_search_params(opts = {})
    removing_record_type_filter = false
    Array(opts["remove_filter_term"]).each do |filter_term|
      removing_record_type_filter = true if ASUtils.json_parse(filter_term).keys.include? 'primary_type'
    end

    search_params = {}

    search_params["filter_term"] = Array(opts["filter_term"] || params["filter_term"]).clone
    search_params["filter_term"].concat(Array(opts["add_filter_term"])) if opts["add_filter_term"]
    search_params["filter_term"] = search_params["filter_term"].reject {|f| Array(opts["remove_filter_term"]).include?(f)} if opts["remove_filter_term"]
    search_params["filter_term"] = search_params["filter_term"].select {|f| SearchResultData.BASE_FACETS.include?(ASUtils.json_parse(f).keys.first)} if removing_record_type_filter

    sort = (opts["sort"] || params["sort"] || (@search_data ? @search_data.sorted? : nil))

    if sort
      sort = sort.split(', ')
      sort[1] = opts["sort2"] if opts["sort2"]
      fields = sort.uniq
      fields = fields.select {|f| multi_columns.compact.include?(f.split.first)} if removing_record_type_filter
      search_params["sort"] = fields.join(', ')
    end

    if (opts["format"] || params["format"]).blank?
      search_params.delete("format")
    else
      search_params["format"] = opts["format"] || params["format"]
    end

    search_params["multiplicity"] = params["multiplicity"] if params["multiplicity"]
    search_params["linker"] = opts["linker"] || params["linker"] || false
    search_params["type"] = opts["type"] || params["type"]
    search_params["facets"] = opts["facets"] || params["facets"] unless removing_record_type_filter
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

    search_params.reject {|k, v| k.blank? or v.blank?}
  end

  def allow_multiselect?
    @allow_multiselect ||= false
  end

  def can_edit_search_result?(record)
    Plugins.edit_roles.each do |edit_role|
      return user_can?(edit_role.role, record['id']) if record['primary_type'] === edit_role.jsonmodel_type
    end

    return user_can?('update_container_record', record['id']) if record['primary_type'] === "top_container"
    return user_can?('update_container_profile_record') if record['primary_type'] === "container_profile"
    return user_can?('create_repository', record['id']) if record['primary_type'] === "repository"
    return user_can?('update_location_record') if record['primary_type'] === "location"
    return user_can?('update_subject_record') if record['primary_type'] === "subject"
    return user_can?('update_classification_record') if ["classification", "classification_term"].include?(record['primary_type'])
    return user_can?('update_agent_record') if Array(record['types']).include?("agent")

    return user_can?('update_accession_record') if record['primary_type'] === "accession"
    return user_can?('update_resource_record') if ["resource", "archival_object"].include?(record['primary_type'])
    return user_can?('update_digital_object_record') if ["digital_object", "digital_object_component"].include?(record['primary_type'])
    return user_can?('update_assessment_record') if record['primary_type'] === "assessment"
    return user_can?('update_event_record') if record['primary_type'] === "event"
    return user_can?('update_location_profile_record') if record['primary_type'] === "location_profile"
  end

  def can_delete_search_results?(record_type)
    case record_type
    when 'accession', 'resource', 'digital_object'
      user_can? 'delete_archival_record'
    when 'assessment'
      user_can? 'delete_assessment_record'
    when 'subject'
      user_can? 'delete_subject_record'
    when 'agent'
      user_can? 'delete_agent_record'
    when 'location'
      user_can? 'update_location_record'
    when 'classification'
      user_can? 'delete_classification_record'
    when 'container_profile'
      user_can? 'update_container_profile_record'
    else
      false
    end
  end

  def locales(model)
    case model
    when 'resource', 'archival_object'
      {'level' => 'archival_record_level',
        'processing_priority' => 'collection_management_processing_priority'}
    when 'accession'
      {'processing_priority' => 'collection_management_processing_priority'}
    when 'subject'
      {'source' => 'subject_source', 'first_term_type' => 'subject_term_type'}
    when 'agent'
      {'source' => 'name_source', 'rules' => 'name_rule', 'primary_type' => 'agent.agent_type'}
    when 'container_profile'
      {'container_profile_dimension_units_u_sstr' => 'dimension_units'}
    when 'location_profile'
      {'location_profile_dimension_units_u_sstr' => 'dimension_units'}
    when 'top_container'
      {'type' => 'container_type'}
    when 'assessment'
      {'assessment_record_types' => '_singular'}
    when 'collection_management'
      {'parent_type' => '_singular'}
    else
      {'primary_type' => '_singular'}
    end
  end


  def add_column(label, opts = {}, block = nil)
    block ||= if opts[:template]
                proc do |record|
                  render_aspace_partial :partial => opts[:template], :locals => {:record => record}
                end
              else
                proc do |record|
                  v = Array(record[opts[:field]] || ASUtils.json_parse(record['json'])[opts[:field]])
                  if v.length > 1
                    content_tag('ul', :style => 'padding-left: 20px;') {
                      Array(v).collect { |i|
                        content_tag('li',
                          process(i, opts))
                      }.join.html_safe
                    }
                  elsif v.length == 1
                    process(v[0], opts)
                  end
                end
              end

    @columns ||= []

    if opts[:sort_by].is_a? Array
      opts[:sort_by].each do |field|
        model = opts[:model] || 'multi'
        @search_data.add_sort_field(field, I18n.t("search.#{model}.#{field}"))
      end
    elsif opts[:sortable]
      opts[:sort_by] ||= opts[:field]
      @search_data.add_sort_field(opts[:sort_by], label)
    end

    col = SearchColumn.new(label, block, opts, @search_data)
    @columns.insert(opts[:index] || -1, col)
  end

  def process(data, opts)
    case opts[:type]
    when 'boolean'
      I18n.t("boolean.#{data}", :default => data.to_s)
    when 'date'
      Date.parse(data)
    else
      if opts[:locale_key] == '_singular'
        I18n.t("#{data}._singular", :default => data.to_s)
      else
        opts[:locale_key] = "enumerations.#{opts[:locale_key]}" unless opts[:locale_key].include?('.')
        I18n.t("#{opts[:locale_key]}.#{data}", :default => data.to_s)
      end
    end
  end

  def add_multiselect_column
    @allow_multiselect = true
    header = ('<label for="select_all" class="sr-only">' +
      I18n.t("search_results.selected") + '</label>' +
      check_box_tag("select_all", 1, false, "autocomplete" => "off")).html_safe

    add_column(header, {:template => 'shared/multiselect',
      :class => 'multiselect-column'})
  end

  def add_pref_columns(models)
    models = Array(models) unless models.is_a? Array
    added = []
    skipped = []
    if models.length > 1
      add_column(I18n.t("search.multi.primary_type"), {:field => 'primary_type', :locale_key => '_singular',
        :sortable => true, :type => 'string'})
      added << 'primary_type'
    end
    for n in 1..AppConfig[:max_search_columns]
      models.each do |model|
        prop = browse_columns["#{model}_browse_column_#{n}"]
        # we do not want to display a column for no value or the relevancy score
        next if added.include?(prop) || !prop || prop == 'no_value' || prop == 'score'
        # we may not want to display context either, in cases like:
        if prop === 'context' && model === 'archival_object' && params["context_filter_term"]
          next if params["context_filter_term"].select {|ft| JSON.parse(ft).has_key?('resource')}
        end
        opts = column_opts[model][prop]
        opts[:locale_key] ||= locales(model)[prop] || "#{model}_#{prop}"
        opts[:model] = model
        # opts[:type] ||= 'string'
        opts[:class] ||= prop

        if opts.fetch(:condition, false)
          unless opts[:condition].call(self)
            skipped << prop
            next
          end
        end

        added << prop
        unless opts[:template]
          if lookup_context.template_exists?("#{prop}_cell", "#{model}s", true)
            opts[:template] = "#{model}s/#{prop}_cell"
          elsif lookup_context.template_exists?("#{prop}_cell", model, true)
            opts[:template] = "#{model}/#{prop}_cell"
          elsif lookup_context.template_exists?("#{prop}_cell", 'search', true)
            opts[:template] = "search/#{prop}_cell"
          end
        end
        add_column(I18n.t("search.#{model}.#{prop}"), opts)
      end
    end
    models.each do |model|
      prop = browse_columns["#{model}_sort_column"]
      next if added.include?(prop) || skipped.include?(prop) || !prop
      added << prop
      opts = prop == 'score' ? { sort_by: 'score' } : column_opts[model][prop]
      @search_data.add_sort_field(opts[:sort_by] ? opts[:sort_by]: prop, I18n.t("search.#{model}.#{prop}"))
    end
  end

  def multi_columns
    column_opts['multi'].collect { |col, opts| opts[:sort_by] } + ['create_time', 'user_mtime']
  end

  def add_actions_column
    add_column(sr_only(I18n.t('search_results.actions')), {:template => 'shared/actions',
      :class => 'actions table-record-actions'})
  end

  def add_linker_column
    add_column(sr_only('Linker'), {},
      proc { |record|
        if params[:multiplicity] === 'many'
          check_box_tag "linker-item", record["id"], false, :"data-object" => record.to_json
        else
          radio_button_tag "linker-item", record["id"], false, :"data-object" => record.to_json
        end
      })
  end

  def sr_only(text)
    ('<span class="sr-only">' + text + '</span>').html_safe
  end

  def add_columns
    if @search_data
      return if @columns
      type = @search_data.get_type
      type = 'agent' if type.include? 'agent'
      type = 'classification' if type == 'classification_term'

      add_multiselect_column if can_delete_search_results?(type) && !(request.path =~ /\/(advanced_)*search/)
      add_linker_column if params[:linker]==='true'

      if params[:include_components]
        case type
        when 'resource'
          add_pref_columns ['resource', 'archival_object']
        when 'digital_object'
          add_pref_columns ['digital_object', 'digital_object_component']
        end
      else
        add_pref_columns(type)
      end
    end

    add_actions_column if !params[:linker] || params[:linker] === 'false'
  end

  def deleted(record)
    params.has_key?("deleted_uri") and Array(params["deleted_uri"]).include?(record["id"])
  end

  def get_ancestor_title(field)
    titles = @ancestor_titles
    return titles[field] if titles.key? field

    begin
      field_json = JSONModel::HTTP.get_json(field)
    # one record might be "found in" another that is suppressed
    # so we will just ignore the error.
    rescue RecordNotFound
      return nil
    end
    return if field_json.nil?

    if field.include?('resources') || field.include?('digital_objects')
      titles[field] = clean_mixed_content(field_json['title'])
    else
      titles[field] = clean_mixed_content(field_json['display_string'])
    end

    titles[field]
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

  def column_opts
    @column_opts ||= SearchAndBrowseColumnConfig.columns
  end

  def fields
    add_columns unless @columns
    @columns.collect { |col| col.field }.compact
  end


  class SearchColumn

    def initialize(label, value_block, opts, search_data)
      @field = opts[:field]
      @label = label
      @value_block = value_block
      @classes = "col "
      @classes << opts[:class] if opts[:class]
      @sortable = opts[:sortable] || false
      @sort_by = opts[:sort_by] || ""
      @search_data = search_data
    end


    def field
      @field
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

    # let's rename this method?
    def class
      @classes << " sortable" if sortable?
      @classes << " sort-#{@search_data.current_sort_direction}" if sortable? && @search_data.sorted_by === @sort_by
      @classes
    end

  end
end
