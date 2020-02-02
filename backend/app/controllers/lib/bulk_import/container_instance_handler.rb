# Supporting multiple containers in the row

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
    
  def build(row,substr)
    {
      :type => @container_types.value(row.fetch("type_1#{substr}", 'Box') || 'Box'),
      :indicator => row.fetch("indicator_1#{substr}", 'Unknown') || 'Unknown',
      :barcode => row.fetch("barcode#{substr}",nil)
    }
  end
    
  # returns a top container JSONModel
  def get_or_create(row, substr, resource, report)
    begin
      top_container = build(row, substr)
      tc_key = key_for(top_container, resource)
      # check to see if we already have fetched one from the db, or created one.
      existing_tc = @top_containers.fetch(tc_key, false) ||  get_db_tc(top_container, resource)
      if !existing_tc
        tc = JSONModel(:top_container).new._always_valid!
        tc.type = top_container[:type]
        tc.indicator = top_container[:indicator]
        tc.barcode = top_container[:barcode] if top_container[:barcode] 
        tc.repository = {'ref' => resource.split('/')[0..2].join('/')}
        #          UpdateUtils.test_exceptions(tc,'top_container')
        tc.save
        report.add_info(I18n.t('bulk_import.created', :what =>"#{I18n.t('bulk_import.tc')} [#{tc.type} #{tc.indicator}]", :id=> tc.uri))
        existing_tc = tc
      end
    rescue Exception => e
      report.add_errors(I18n.t('bulk_import.error.no_tc', :why => e.message + " in linked_objects"))
      existing_tc = nil
    end
    @top_containers[tc_key] = existing_tc if existing_tc
    existing_tc
  end

  def get_db_tc(top_container, resource_uri)
    repo_id = resource_uri.split('/')[2]
    if !(ret_tc = get_db_tc_by_barcode(top_container[:barcode], repo_id))
      tc_str = "#{top_container[:type]} #{top_container[:indicator]}"
      tc_str += ": [#{top_container[:barcode]}]" if top_container[:barcode]
      tc_params = {}
      tc_params["type[]"] = 'top_container'
      tc_params["q"] = "display_string:\"#{tc_str}\" AND collection_uri_u_sstr:\"#{resource_uri}\""
      ret_tc = search(repo_id,tc_params, :top_container,'', "display_string:#{tc_str}")
    end
    ret_tc
  end
    
  def get_db_tc_by_barcode(barcode, repo_id)
    ret_tc = nil
    if barcode
      tc_params = {}
      tc_params["type[]"] = 'top_container'
      tc_params["q"] = "barcode_u_sstr:\"#{barcode}\""
      ret_tc = search(repo_id,tc_params, :top_container)
    end
    ret_tc
  end

  def create_container_instance(row, substr, resource_uri,report)
    instance = nil
    raise  BulkImportException.new(I18n.t('bulk_import.error.missing_instance_type')) if row["cont_instance_type#{substr}"].blank?
    begin
      tc = get_or_create(row, substr, resource_uri, report)
      sc = {'top_container' => {'ref' => tc.uri},
        'jsonmodeltype' => 'sub_container'}
      %w(2 3).each do |num|
        if row["type_#{num}#{substr}"]
          sc["type_#{num}"] = @container_types.value(row["type_#{num}#{substr}"])
          sc["indicator_#{num}"] = row["indicator_#{num}#{substr}"] || 'Unknown'
        end
      end
      instance = JSONModel(:instance).new._always_valid!
      instance.instance_type = @instance_types.value(row["cont_instance_type#{substr}"])
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
