class ContainerInstanceHandler < Handler
  def initialize(current_user, validate_only = false)
    super
    @top_containers = {}
    @container_types ||= CvList.new("container_type", @current_user)
    @instance_types ||= CvList.new("instance_instance_type", @current_user) # for when we move instances over here
  end

  def renew
    clear(@container_types)
    clear(@instance_types)
  end

  def key_for(top_container, resource)
    key = "'#{resource}' #{top_container[:type]}: #{top_container[:indicator]}"
    key += " #{top_container[:barcode]}" if top_container[:barcode]
    key
  end

  def build(type, indicator, barcode)
    {
      :type => @container_types.value(type || "Box"),
      :indicator => indicator || "Unknown",
      :barcode => barcode,
    }
  end

  def get_top_container_json_from_hash(type, indicator, barcode, resource)
    top_container_json = build(type, indicator, barcode)
    tc_key = key_for(top_container_json, resource)
    tc = @top_containers.fetch(tc_key, nil)
    tc
  end

  # returns a top container JSONModel
  def get_or_create(type, indicator, barcode, resource, report)
    begin
      if !@container_types.value(type)
        @container_types.add_value_to_enum(type)
      end
      top_container = build(type, indicator, barcode)
      tc_key = key_for(top_container, resource)
      # check to see if we already have fetched one from the db, or created one.
      existing_tc = @top_containers.fetch(tc_key, false) || get_existing_tc(top_container, resource)
      if !existing_tc
        tc = JSONModel(:top_container).new._always_valid!
        tc.type = top_container[:type]
        tc.indicator = top_container[:indicator]
        tc.barcode = top_container[:barcode] if top_container[:barcode]
        tc.repository = { "ref" => resource.split("/")[0..2].join("/") }
        tc = save(tc, TopContainer)
        created(tc, "#{I18n.t("bulk_import.tc")}", "#{I18n.t("bulk_import.tc")} [#{tc.type} #{tc.indicator}]", report)
        existing_tc = tc
      end
    rescue Exception => e
      raise BulkImportException.new(e.message)
    end
    @top_containers[tc_key] = existing_tc if existing_tc
    existing_tc
  end

  def get_existing_tc(top_container, resource_uri)
    existing = if !top_container[:barcode].nil?
                 get_tc_by_barcode(top_container[:barcode], resource_uri)
               else
                 get_tc_by_type_indicator(top_container, resource_uri)
               end

    existing
  end

  def get_tc_by_type_indicator(top_container, resource_uri)
    tc_str = "#{top_container[:type]} #{top_container[:indicator]}"
    tc_params = {}
    tc_params[:q] = "display_string:\"#{tc_str}\" AND collection_uri_u_sstr:\"#{resource_uri}\""
    ret_tc = search(nil, tc_params, :top_container, "top_container", "display_string:#{tc_str}")

    ret_tc
  end

  def get_tc_by_barcode(barcode, resource_uri)
    repo_id = resource_uri.split("/")[2]
    ret_tc = nil
    if barcode
      begin
        tc_params = {}
        tc_params[:q] = "barcode_u_sstr:\"#{barcode}\""
        ret_tc = search(repo_id, tc_params, :top_container, "top_container")
      rescue Exception => e
        # we don't care why
      end
    end

    ret_tc
  end

  def validate_container_instance(instance_type, type, instance, errs, subcont = {})
    sc = { "jsonmodeltype" => "sub_container" }
    if instance_type.nil?
      errs << I18n.t("bulk_import.error.missing_instance_type")
    else
      instance.instance_type = value_check(@instance_types, instance_type, errs)
    end
    %w(2 3).each do |num|
      if subcont["type_#{num}"]
        sc["type_#{num}"] = value_check(@container_types, subcont["type_#{num}"], errs)
        sc["indicator_#{num}"] = subcont["indicator_#{num}"] || "Unknown"
        sc["barcode_#{num}"] = subcont["barcode_#{num}"] || nil
      end
    end
    sc
  end

  #Formats the container instance without a db retrieval or creation
  def format_container_instance(instance_type, tc, subcont = {})
    instance = nil
    sc = {'top_container' => {'ref' => tc.uri}, 'jsonmodel_type' => 'sub_container'}
    %w(2 3).each do |num|
      if subcont["type_#{num}"]
        sc["type_#{num}"] = @container_types.value(subcont["type_#{num}"])
        sc["indicator_#{num}"] = subcont["indicator_#{num}"] || 'Unknown'
        sc["barcode_#{num}"] = subcont["barcode_#{num}"] || nil
      end
    end
    instance = JSONModel(:instance).new._always_valid!
    instance.instance_type = @instance_types.value(instance_type)
    instance.sub_container = JSONModel(:sub_container).from_hash(sc)
    instance
  end

  def create_container_instance(instance_type, type, indicator, barcode, resource_uri, report, subcont = {})
    errs = []
    instance = JSONModel(:instance).new._always_valid!
    sc = validate_container_instance(instance_type, type, instance, errs, subcont)
    tc = get_or_create(type, indicator, barcode, resource_uri, report)
    unless @validate_only || tc.nil? || sc.nil?
      begin
        sc["top_container"] = { "ref" => tc.uri }
        instance.sub_container = JSONModel(:sub_container).from_hash(sc)
      rescue BulkImportException => ee
        errs << ee.message
      rescue Exception => e
        errs << ee.message
      end
    end
    if !errs.empty?
      raise BulkImportException.new(errs.join("; "))
    end
    %w(2 3).each do |num|
      if subcont["type_#{num}"]
        sc["type_#{num}"] = value_check(@container_types, subcont["type_#{num}"], errs)
        sc["indicator_#{num}"] = subcont["indicator_#{num}"] || "Unknown"
        sc["barcode_#{num}"] = subcont["barcode_#{num}"] || nil
      end
    end
    instance
  end

end  # of container handler
