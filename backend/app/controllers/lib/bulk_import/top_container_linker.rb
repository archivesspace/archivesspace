require_relative "bulk_import_spreadsheet_parser"


class TopContainerLinker < BulkImportSpreadsheetParser
  def run
    begin
      initialize_info
      initialize_handler_enums
      process_spreadsheet_data
    end
    return true
  end
  
  
  def initialize(input_file, file_content_type, opts = {}, current_user)
    super(input_file, file_content_type, opts, current_user)
  end
  
  def initialize_handler_enums
    @cih = ContainerInstanceHandler.new(@current_user)
  end

  
  #We first want to validate spreadsheet data to make sure that the
  #required fields exist as well as verify that the populated fields
  #have valid data
  def process_spreadsheet_data
    begin
      while (row = @rows.next)
        @counter += 1
        row_hash = get_row_hash(row)
        begin
          @report.new_row(@counter)
          errors = process_row(row_hash)
          if !errors.empty?
            raise TopContainerLinkerException.new(I18n.t("top_container_linker.error.error_linking_tc_to_ao: ", :why => errors))
          end
          @rows_processed += 1
        rescue StopTopContainerLinkingException => se
          @report.add_errors(I18n.t("bulk_import.error.stopped", :row => @counter, :msg => se.message))
          raise StopIteration.new
        rescue TopContainerLinkerException => e
          @error_rows += 1
          @report.add_errors(e.message)
        end
        @report.end_row
      end
    rescue StopIteration
      # we just want to catch this without processing further
      @report.end_row
    end
    if @rows_processed == 0
      raise TopContainerLinkerException.new(I18n.t("bulk_import.error.no_data"))
    end
    
  end


  # save the archival object, then revive it
  def ao_save(ao)
    revived = nil
    begin
      obj = ArchivalObject.get_or_die(ao.id)
      archObj = obj.update_from_json(ao)
      objs = ArchivalObject.sequel_to_jsonmodel([archObj])
      revived = objs[0] if !objs.empty?
    rescue ValidationException => ve
      Log.error(ve.message)
      Log.error(ve.backtrace)
      raise TopContainerLinkerException.new(I18n.t("bulk_import.error.ao_validation", :err => ve.errors))
    rescue Exception => e
      Log.error("UNEXPECTED ao save error: #{e.message}\n#{e.backtrace}")
      Log.error(ASUtils.jsonmodels_to_hashes(ao).pretty_inspect) if ao
      raise e
    end
    revived
  end

  # look for all the required fields to make sure they are legit
  def process_row(row_hash)
    err_arr = []
    begin
      ao = nil
      # Check that the archival object ref id exists
      ref_id = row_hash[REF_ID]
      if ref_id.nil?
        err_arr.push I18n.t("top_container_linker.error.ref_id_miss", :row_num => @counter.to_s)
      else 
        #Check that the AO can be found in the db
        ao = archival_object_from_ref(ref_id.strip)
        if (ao.nil?)
          err_arr.push I18n.t("top_container_linker.error.ao_not_in_db", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        else
          @report.add_archival_object(ao)
        end
      end
     
      #If the AO is nil, then just stop here before checking anything else
      if ao.nil?
        raise TopContainerLinkerException.new("No AO found;" + err_arr)
      end
      
      #Check that the instance type exists
      instance_type = row_hash[INSTANCE_TYPE]
      if instance_type.nil?
        err_arr.push I18n.t("top_container_linker.error.instance_type_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      #Check that either the Top Container Indicator or Top Container Record No. is present
      tc_indicator = row_hash[TOP_CONTAINER_INDICATOR]
      tc_record_no = row_hash[TOP_CONTAINER_ID]
      #Both missing  
      if (tc_indicator.nil? && tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      #Both exist
      if (!tc_indicator.nil? && !tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_exist", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      #Container type/Container indicator combo already exists 
      tc_type = row_hash[TOP_CONTAINER_TYPE]
      tc_obj = nil
      if (!tc_indicator.nil? && !tc_type.nil?)
        type_id = BackendEnumSource.id_for_value("container_type",tc_type.strip)
        tc_jsonmodel_obj = find_top_container({:indicator => tc_indicator, :type_id => type_id})
        display_indicator = tc_indicator;
        if (tc_jsonmodel_obj.nil?)
          #Create new TC 
          tc_obj = create_top_container_instance(instance_type, tc_indicator, tc_type, row_hash, err_arr, ref_id, @counter.to_s)
        else
          tc_obj = create_top_container_instance(instance_type, tc_jsonmodel_obj.indicator, tc_jsonmodel_obj.type, row_hash, err_arr, ref_id, @counter.to_s)
          display_indicator = tc_jsonmodel_obj.indicator
        end
      elsif (!tc_record_no.nil?)
        tc_jsonmodel_obj = TopContainer.get_or_die(tc_record_no.strip)
        if tc_jsonmodel_obj.nil?
          #Cannot find TC record with ID
          err_arr.push I18n.t("top_container_linker.error.tc_record_no_missing", :tc_id=> tc_record_no, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        else
          tc_obj = create_top_container_instance(instance_type, tc_jsonmodel_obj.indicator, tc_jsonmodel_obj.type, row_hash, err_arr, ref_id, @counter.to_s)
          display_indicator = tc_jsonmodel_obj.indicator
        end
      end
      
      if (!tc_obj.nil?)
        ao.instances ||= []
        ao.instances << tc_obj
        @report.add_info("Adding Top Container Instance " + instance_type.capitalize  + " " + display_indicator + " to Archival Object " + ref_id)
      end
      ao_save(ao)      
    rescue StopTopContainerLinkingException => se
      err_arr.join("; ")
      raise StopTopContainerLinkingException.new(se.message + "; "  + err_arr)
    rescue TopContainerLinkerException => te
      err_arr.join("; ")
      raise TopContainerLinkerException.new(te.message + "; " + err_arr)
    rescue Exception => e
      Log.error(["UNEXPLAINED EXCEPTION on process_row", e.message, e.backtrace, row_hash].pretty_inspect)
    end
    err_arr.join("; ")
  end
  
  def create_top_container_instance(instance_type, indicator, type, row_hash, err_arr, ref_id, row_num)
    barcode = row_hash[TOP_CONTAINER_BARCODE]
    if (!barcode.nil?)
      tc_obj = find_top_container({:barcode => barcode.strip})
      if (tc_obj.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_barcode_exists", :barcode=> barcode, :ref_id => ref_id.to_s, :row_num => row_num)
      end
    end
    #Check if the barcode_2 already exists in the db (fail if so).  
    #This will be put in place when Harvard's code is merged
    #barcode_2 = row_hash["Child Barcode"]
    #if (!barcode_2.nil?)
      #barcode_2 = barcode_2.strip
      #sc_obj = sub_container_from_barcode(barcode_2)
      #if (!sc_obj.nil?)
      #  err_arr.push I18n.t("top_container_linker.error.sc_barcode_exists", :barcode=> barcode_2, :ref_id => ref_id.to_s, :row_num => row_num)
      #end
    #end
    #Check if the location ID can be found in the db
    child_type = row_hash[CHILD_TYPE]
    child_indicator = row_hash[CHILD_INDICATOR]
    subcontainer = {}
    if (!child_type.nil? && !child_indicator.nil?)
      subcontainer = { "type_2" => child_type.strip,
                      "indicator_2" => child_indicator.strip}#,
    #                  "barcode_2" => barcode_2}
    end

    instance = nil
    begin
     instance = @cih.create_container_instance(instance_type,
                                                type, indicator, barcode, @resource_ref, @report, subcontainer)
    rescue Exception => e
      @report.add_errors(I18n.t("top_container_linker.error.no_tc", :ref_id => ref_id.to_s, :row_num => row_num, why: e.message))
      instance = nil
    end
         
    #Check if the location ID can be found in the db
    loc_id = row_hash[LOCATION_ID]
    if (!loc_id.nil?)
      loc = Location.get_or_die(loc_id.strip)
      if (loc.nil?)
        err_arr.push I18n.t("top_container_linker.error.loc_not_in_db", :loc_id=> loc_id.to_s, :ref_id => ref_id.to_s, :row_num => row_num)
      else
        begin
          loc_jsonmodel = Location.sequel_to_jsonmodel([loc])
          instance = add_current_location(instance, loc_jsonmodel)
        rescue Exception => e
          @report.add_errors(I18n.t("top_container_linker.error.problem_adding_current_location", :ref_id => ref_id.to_s, :row_num => row_num, why: e.message))
          instance = nil
        end
      end
    end
    
    #Check if Container Profile Record No. can be found in the db 
    cp_id = row_hash[CONTAINER_PROFILE_ID]
    if (!cp_id.nil?)
      cp = ContainerProfile.get_or_die(cp_id.strip)
      if (cp.nil?)
        err_arr.push I18n.t("top_container_linker.error.cp_not_in_db", :cp_id=> cp_id.to_s, :ref_id => ref_id.to_s, :row_num => row_num)
        else
          begin
            cp_jsonmodel = ContainerProfile.sequel_to_jsonmodel([cp])
            instance = set_container_profile(instance, cp_jsonmodel)
          rescue Exception => e
            @report.add_errors(I18n.t("top_container_linker.error.problem_setting_container_profile", :ref_id => ref_id.to_s, :row_num => row_num, why: e.message))
            instance = nil
          end
        end
    end
    
    return instance
  end



end
