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

    if show_identifier_column? 
      search_params["display_identifier"] = true
    end

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


  def allow_multi_select?
    @show_multiselect_column
  end


  def show_record_type?
    !@search_data.single_type? || (@search_data[:criteria].has_key?("type[]") && @search_data[:criteria]["type[]"].include?("agent"))
  end


  # in case the title needs to be handled among other columns
  def no_title!
    @no_title = true
  end

  def show_identifier_column?
    @display_identifier
  end


  def show_context_column?
    @display_context
  end


  def context_column_header_label
    @context_column_header or I18n.t("search_results.context")
  end


  def show_title_column?
    @search_data.has_titles? && !@no_title
  end


  def title_column_header(title_header)
    @title_column_header = title_header
  end


  def title_column_header_label
    @title_column_header or I18n.t("search_results.result_title")
  end


  def title_sort_label
    @title_column_header or I18n.t("search_sorting.title_sort")
  end

  def identifier_column_header_label
    I18n.t("search_results.result_identifier")
  end

  def identifier_for_search_result(result)
    identifier = IDENTIFIER_FOR_SEARCH_RESULT_LOOKUP.fetch(result["primary_type"], "")
    unless identifier.empty?
      if result.has_key? identifier
        identifier = result[identifier]
      else
        json       = JSON.parse(result["json"])
        identifier = json.fetch(identifier, "")
      end
    end
    identifier.to_s.html_safe
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


  def add_column(label, block, opts = {})
    @extra_columns ||= []

    if opts[:sortable] && opts[:sort_by]
      @search_data.sort_fields << opts[:sort_by]
    end

    col = ExtraColumn.new(label, block, opts, @search_data)
    @extra_columns.push(col)
  end

  def add_identifier_column
    prop = "identifier" 
    add_column(identifier_column_header_label,
                   proc { |record|
                      record[prop] || ASUtils.json_parse(record['json'])[prop]
                   }, :sortable => true, :sort_by => prop)

  end

  def add_browse_columns(model, enum_locales = {})
    (1..5).to_a.each do |n|
      prop = user_prefs["#{model}_browse_column_#{n}"]
      if prop && prop != 'no_value'
        enum_locale_key = enum_locales.has_key?(prop) ? enum_locales[prop] : "#{model}_#{prop}"
        add_column(I18n.t("#{model}.#{prop}"),
                   proc { |record|
                     v = record[prop] || ASUtils.json_parse(record['json'])[prop]
                     I18n.t("enumerations.#{enum_locale_key}.#{v}", :default => v.to_s)
                   }, :sortable => true, :sort_by => prop)
      end
    end
  end

  def get_ancestor_title(field)
    if field.include?('resources') || field.include?('digital_objects')
      clean_mixed_content(JSONModel::HTTP.get_json(field)['title'])
    else
      clean_mixed_content(JSONModel::HTTP.get_json(field)['display_string'])
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
      ancestors = result['collection_uri_u_sstr']
    when result['primary_type'] == 'digital_object_component'
      ancestors = result['digital_object'].split
    else
      ancestors = ['']
    end
  end

  def extra_columns
    @extra_columns
  end


  def extra_columns?
    return false if @extra_columns == nil

    !@extra_columns.empty?
  end


  class ExtraColumn

    def initialize(label, value_block, opts, search_data)
      @label = label
      @value_block = value_block
      @classes = "col " << (opts[:class] || "")
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
