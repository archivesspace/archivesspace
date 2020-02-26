class ContainerInstanceHandler < Handler

  def initialize(current_user)
    @top_containers = {}
    @container_types ||= CvList.new('container_type', current_user)
    @instance_types ||= CvList.new('instance_instance_type', current_user) # for when we move instances over here
  end

  def renew
    clear( @container_types)
    clear(@instance_types)
  end

  def key_for(top_container, resource)
    key = "'#{resource}' #{top_container[:type]}: #{top_container[:indicator]}"
    key += " #{top_container[:barcode]}" if top_container[:barcode]
    key
  end
    
  def build(type, indicator, barcode)
    {
      :type => @container_types.value(type || 'Box'),
      :indicator => indicator || 'Unknown',
      :barcode => barcode
    }
  end
    
  # returns a top container JSONModel
  def get_or_create(type, indicator, barcode, resource, report)
    begin
      top_container = build(type, indicator, barcode)
      tc_key = key_for(top_container, resource)
      # check to see if we already have fetched one from the db, or created one.
      existing_tc = @top_containers.fetch(tc_key, false) ||  get_db_tc(top_container, resource)
      if !existing_tc
        tc = JSONModel(:top_container).new._always_valid!
        tc.type = top_container[:type]
        tc.indicator = top_container[:indicator]
        tc.barcode = top_container[:barcode] if top_container[:barcode] 
        tc.repository = {'ref' => resource.split('/')[0..2].join('/')}
        tc = save(tc, TopContainer)
        report.add_info(I18n.t('bulk_import.created', :what =>"#{I18n.t('bulk_import.tc')} [#{tc.type} #{tc.indicator}]", :id=> tc.uri))
        existing_tc = tc
      end
    rescue Exception => e
      raise BulkImportException.new(e.message)
    end
    @top_containers[tc_key] = existing_tc if existing_tc
    existing_tc
  end

  def get_db_tc(top_container, resource_uri)
    repo_id = resource_uri.split('/')[2]
    if !(ret_tc = get_db_tc_by_barcode(top_container[:barcode], repo_id))
      tc_str = "#{top_container[:type]} #{top_container[:indicator]}"
      # tc_str += ": [#{top_container[:barcode]}]" if top_container[:barcode]
      tc_params = {}
      tc_params[:q] = "display_string:\"#{tc_str}\" AND collection_uri_u_sstr:\"#{resource_uri}\""
      ret_tc = search(nil,tc_params, :top_container,'top_container', "display_string:#{tc_str}")
    end
    ret_tc
  end
    
  def get_db_tc_by_barcode(barcode, repo_id)
    ret_tc = nil
    if barcode
      begin
        tc_params = {}
        tc_params[:q] = "barcode_u_sstr:\"#{barcode}\""
        ret_tc = search(repo_id,tc_params, :top_container, 'top_container')
      rescue Exception => e
        # we don't care why
      end
    end
    ret_tc
  end

  def create_container_instance(instance_type, type, indicator, barcode, resource_uri,report, subcont = {})
    instance = nil
    raise  BulkImportException.new(I18n.t('bulk_import.error.missing_instance_type')) if instance_type.nil?
    begin
      tc = get_or_create(type, indicator, barcode, resource_uri, report)
      sc = {'top_container' => {'ref' => tc.uri}, 'jsonmodeltype' => 'sub_container'}
      %w(2 3).each do |num|
        if subcont["type_#{num}"]
          sc["type_#{num}"] = @container_types.value(subcont["type_#{num}"])
          sc["indicator_#{num}"] = subcont["indicator_#{num}"] || 'Unknown'
        end
      end
      instance = JSONModel(:instance).new._always_valid!
      instance.instance_type = @instance_types.value(instance_type)
      instance.sub_container = JSONModel(:sub_container).from_hash(sc)
    rescue BulkImportException => ee
      raise ee
    rescue Exception => e
      msg = e.message #+ "\n" + e.backtrace()[0]
      raise BulkImportException.new(msg)
    end
    instance
  end

end  # of container handler
