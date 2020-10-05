require_relative "crud_helpers"

# contains  methods that might be needed for more than one bulk import converter
module BulkImportMixins
  include CrudHelpers
  # METHOD(s)
  def resolves
    ["subjects", "related_resources", "linked_agents",
     "revision_statements",
     "container_locations", "digital_object", "classifications",
     "related_agents", "resource", "parent", "creator",
     "linked_instances", "linked_records", "related_accessions",
     "linked_events", "linked_events::linked_records",
     "linked_events::linked_agents",
     "top_container", "container_profile", "location_profile",
     "owner_repo"]
  end
  
  def ao_save(ao)
      revived = nil
      if @validate_only
        valid(ao, I18n.t("ao"))
        ao.uri = ao.uri || "valid"
        revived = ao
      else
        begin
          archObj = nil
          if ao.id.nil?
            archObj = ArchivalObject.create_from_json(ao)
          else
            obj = ArchivalObject.get_or_die(ao.id)
            archObj = obj.update_from_json(ao)
          end
          objs = ArchivalObject.sequel_to_jsonmodel([archObj])
          revived = objs[0] if !objs.empty?
        rescue JSONModel::ValidationException => ve
          raise BulkImportException.new(I18n.t("bulk_import.error.ao_validation", :err => ve.errors))
        rescue Exception => e
          Log.error("UNEXPECTED ao save error: #{e.message}\n#{e.backtrace}")
          Log.error(ASUtils.jsonmodels_to_hashes(ao).pretty_inspect) if ao
          raise e
        end
      end
      revived
    end
    
  def resource_from_ref(ead_id)
    dataset = CrudHelpers.scoped_dataset(Resource, {:ead_id => ead_id})
    resource = nil
    if !dataset.empty?
      objs = dataset.respond_to?(:all) ? dataset.all : dataset
      jsonms = Resource.sequel_to_jsonmodel(objs)
      if jsonms.length == 1
        resource = jsonms[0]
      else
        raise BulkImportException.new(I18n.t('bulk_import.error.resource_ref_id', :ref_id => ead_id))
      end
    end
    resource 
  end

def archival_object_from_ref(ref_id)
    dataset = CrudHelpers.scoped_dataset(ArchivalObject, { :ref_id => ref_id })
    ao = nil
    if !dataset.empty?
      objs = dataset.respond_to?(:all) ? dataset.all : dataset
      jsonms = ArchivalObject.sequel_to_jsonmodel(objs)
      if jsonms.length == 1
        ao = jsonms[0]
      else
        raise BulkImportException.new(I18n.t("bulk_import.error.bad_ao_ref_id", :ref_id => ref_id))
      end
    end
    ao
  end

  def archival_object_from_ref_or_uri(ref_id, uri)
    ao = nil
    errs = ""
    if uri.nil? && ref_id.nil?
      errs = I18n.t("bulk_import.error.no_uri_or_ref")
    elsif !uri.nil?
      begin
        ao = archival_object_from_uri(uri)
      rescue BulkImportException => e
        errs = e.message
      end
    elsif ao.nil? && !ref_id.nil?
      begin
        ao = archival_object_from_ref(ref_id)
      rescue BulkImportException => e
        errs = "#{errs} #{e.message}"
      end
    end
    { :ao => ao, :errs => errs }
  end

  # accepts either the full URI or just the ID
  def archival_object_from_uri(uri)
    ao = nil
    begin
      uris = uri.split("/")
      aoid = uris.length == 1 ? uri : uris[4]
      ao = ArchivalObject.to_jsonmodel(Integer(aoid))
    rescue
      raise BulkImportException.new(I18n.t("bulk_import.error.bad_ao_uri", :uri => uri))
    end
    ao
    ao
  end
  

  #Finds the top container using the hash values (AND clause only)
  def find_top_container(where_params)
    dataset = CrudHelpers.scoped_dataset(TopContainer, where_params)
    tc = nil
    if !dataset.empty?
      objs = dataset.respond_to?(:all) ? dataset.all : dataset
      jsonms = TopContainer.sequel_to_jsonmodel(objs)
      if jsonms.length > 0
       tc = jsonms[0]
      else
        raise BulkImportException.new(I18n.t('bulk_import.error.find_tc', :where => where_params.pretty_inspect))
      end
    end
    tc
  end 
  
 def indicator_and_type_exist_for_resource?(ead_id, indicator, type_id)
   
    return TopContainer
      .join(:top_container_link_rlshp, :top_container_link_rlshp__top_container_id => :top_container__id)
      .join(:sub_container, :sub_container__id => :top_container_link_rlshp__sub_container_id)
      .join(:instance, :instance__id => :sub_container__instance_id)
      .join(:archival_object, :archival_object__id => :instance__archival_object_id)
      .join(:resource, :resource__id => :archival_object__root_record_id)
      .filter(:resource__ead_id => ead_id, :indicator => indicator, :type_id => type_id).count > 0
  end

  def sub_container_from_barcode(barcode)
    dataset = CrudHelpers.scoped_dataset(SubContainer, {:barcode_2 => barcode})
    sc = nil
    if !dataset.empty?
      objs = dataset.respond_to?(:all) ? dataset.all : dataset
      jsonms = SubContainer.sequel_to_jsonmodel(objs)
      if jsonms.length > 0
       sc = jsonms[0]
      else
        raise BulkImportException.new(I18n.t('bulk_import.error.sc_barcode', :barcode => barcode))
      end
    end
    sc
  end
  

  #Finds the top container using the hash values (AND clause only)
  def find_top_container(where_params)
    dataset = CrudHelpers.scoped_dataset(TopContainer, where_params)
    tc = nil
    if !dataset.empty?
      objs = dataset.respond_to?(:all) ? dataset.all : dataset
      jsonms = TopContainer.sequel_to_jsonmodel(objs)
      if jsonms.length > 0
       tc = jsonms[0]
      else
        raise BulkImportException.new(I18n.t('bulk_import.error.find_tc', :where => where_params.pretty_inspect))
      end
    end
    tc
  end 
  
 def indicator_and_type_exist_for_resource?(ead_id, indicator, type_id)
   
    return TopContainer
      .join(:top_container_link_rlshp, :top_container_link_rlshp__top_container_id => :top_container__id)
      .join(:sub_container, :sub_container__id => :top_container_link_rlshp__sub_container_id)
      .join(:instance, :instance__id => :sub_container__instance_id)
      .join(:archival_object, :archival_object__id => :instance__archival_object_id)
      .join(:resource, :resource__id => :archival_object__root_record_id)
      .filter(:resource__ead_id => ead_id, :indicator => indicator, :type_id => type_id).count > 0
  end

  def sub_container_from_barcode(barcode)
    dataset = CrudHelpers.scoped_dataset(SubContainer, {:barcode_2 => barcode})
    sc = nil
    if !dataset.empty?
      objs = dataset.respond_to?(:all) ? dataset.all : dataset
      jsonms = SubContainer.sequel_to_jsonmodel(objs)
      if jsonms.length > 0
       sc = jsonms[0]
      else
        raise BulkImportException.new(I18n.t('bulk_import.error.sc_barcode', :barcode => barcode))
      end
    end
    sc
  end

  def created(obj, type, message, report)
    if @validate_only
      report.add_info(I18n.t("bulk_import.could_be", :what => message))
    else
      report.add_info(I18n.t("bulk_import.created", :what => message, :id => obj.uri))
    end
  end

  def created(obj, type, message, report)
    if @validate_only
      report.add_info(I18n.t("bulk_import.could_be", :what => message))
    else
      report.add_info(I18n.t("bulk_import.created", :what => message, :id => obj.uri))
    end
  end

  def resource_match(resource, ead_id, uri)
    if uri.nil? && ead_id.nil?
      raise BulkImportException.new(I18n.t("bulk_import.error.row_missing_ead_uri"))
    end
    match = false
    # try uri first
    if !uri.nil?
      if uri == resource["uri"]
        match = true
      else
        raise BulkImportException.new(I18n.t("bulk_import.error.uri_mismatch", :res_uri => resource[:record_uri], :row_uri => uri))
      end
    elsif !ead_id.nil?
      if ead_id == resource["ead_id"]
        match = true
      else
        raise BulkImportException.new(I18n.t("bulk_import.error.res_ead")) if resource["ead_id"].nil?
        raise BulkImportException.new(I18n.t("bulk_import.error.ead_mismatch", :res_ead => resource["ead_id"], :row_ead => ead_id))
      end
    end
    match
  end

  def valid(obj, what)
    ret_val = false
    begin
      test_exceptions(obj)
      ret_val = true
    rescue Exception => ex
      raise BulkImportException.new(I18n.t("bulk_import.error.validation_error", :what => what, :err => ex.message))
    end
    ret_val
  end

  def value_check(cvlist, value, errs)
    ret_val = nil
    begin
      ret_val = cvlist.value(value)
    rescue Exception => ex
      errs << ex.message
    end
    ret_val
  end

  # The following methods assume @report is defined, and is a BulkImportReport object
  def create_date(dates_label, date_begin, date_end, date_type, expression, date_certainty)
    date_str = "(Date: type:#{date_type}, label: #{dates_label}, begin: #{date_begin}, end: #{date_end}, expression: #{expression})"
    begin
      date_type = @date_types.value(date_type || "inclusive")
    rescue Exception => e
      @report.add_errors(I18n.t("bulk_import.error.date_type", :what => date_type, :date_str => date_str))
    end
    begin
      date = { "date_type" => date_type,
               "label" => @date_labels.value(dates_label || "creation") }
    rescue Exception => e
      @report.add_errors(I18n.t("bulk_import.error.date_label",
                                :what => dates_label, :date_str => date_str))
      #don't bother processsing if the label mis-matches
      return nil
    end

    if date_certainty
      begin
        date["certainty"] = @date_certainty.value(date_certainty)
      rescue Exception => e
        @report.add_errors(I18n.t("bulk_import.error.certainty", :what => e.message, :date_str => date_str))
      end
    end
    date["begin"] = date_begin if date_begin
    date["end"] = date_end if date_end
    date["expression"] = expression if expression
    invalids = JSONModel::Validations.check_date(date)
    unless (invalids.nil? || invalids.empty?)
      err_msg = ""
      invalids.each do |inv|
        err_msg << " #{inv[0]}: #{inv[1]}"
      end
      @report.add_errors(I18n.t("bulk_import.error.invalid_date", :what => err_msg, :date_str => date_str))
      return nil
    end
    if date_type == "single" && !date_end.nil?
      @report.add_errors(I18n.t("bulk_import.warn.single_date_end", :date_str => date_str))
    end
    d = JSONModel(:date).new(date)
  end

  def handle_notes(ao, hash, dig_obj = false)
    @nh = NotesHandler.new
    publish = ao.publish
    errs = []
    notes_keys = hash.keys.grep(/^n_/)
    if notes_keys
      notes_keys.each do |key|
        unless hash[key].nil?
          content = hash[key]
          type = key.match(/n_(.+)$/)[1]
          pubnote = hash["p_#{type}"]
          if pubnote.nil?
            pubnote = publish
          else
            pubnote = (pubnote == "1")
          end
          begin
            note = @nh.create_note(type, content, pubnote, dig_obj)
            ao.notes.push(note) if !note.nil?
          rescue BulkImportException => bei
            errs.push([bei.message])
          end
        end
      end
    end
    errs
  end

  def test_exceptions(obj, what = "")
    ret_val = false
    begin
      obj._exceptions
      ret_val = true
    rescue Exception => e
      raise BulkImportException.new("editable?") if e.message.include?("editable?")
      raise e
    end
    ret_val
  end
end

class BulkImportException < Exception
end

class BulkImportDisambigException < BulkImportException
end

class StopBulkImportException < Exception
end
