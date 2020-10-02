require_relative "bulk_import_parser"
require_relative "bulk_import_report"
require_relative "top_container_linker_mixins"

class TopContainerLinker < BulkImportParser
  include BulkImportMixins
  
  #ASpace field headers row indicator
  START_MARKER = /ArchivesSpace field code/.freeze

  attr_reader :report
  
  def initialize(input_file, content_type, current_user, opts)
    super(input_file, content_type, current_user, opts, nil)
    @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:rid]}"
    @start_marker = START_MARKER
  end
  
  def initialize_handler_enums
    @cih = ContainerInstanceHandler.new(@current_user)
  end
  
  # save (create/update) the archival object, then revive it
  
  def ao_save(ao)
    revived = nil
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
    rescue ValidationException => ve
      raise BulkImportException.new(I18n.t("bulk_import.error.ao_validation", :err => ve.errors))
    rescue Exception => e
      Log.error("UNEXPECTED ao save error: #{e.message}\n#{e.backtrace}")
      Log.error(ASUtils.jsonmodels_to_hashes(ao).pretty_inspect) if ao
      raise e
    end
    revived
  end


  # look for all the required fields to make sure they are legit
  def process_row(row_hash = nil)
    Log.info("PROCESS ROW")
    #This allows the processing of a single row
    if (!row_hash.nil?)
      @row_hash = row_hash
      @report = BulkImportReport.new
      @counter += 1
      @report.new_row(@counter)
    end
    err_arr = []
    begin
      ao = nil
      # Check that the archival object ref id exists
      ref_id = @row_hash[REF_ID]

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
        raise BulkImportException.new("No AO found;" + err_arr)
      end
      
      ead_id = @row_hash[EAD_ID]
      if ead_id.nil?
        err_arr.push I18n.t("top_container_linker.error.ead_id_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      else 
        #Check that the AO can be found in the db
        resource = resource_from_ref(ead_id.strip)
        if (resource.nil?)
          err_arr.push I18n.t("top_container_linker.error.resource_not_in_db", :ead_id => ead_id.to_s, :row_num => @counter.to_s)
        elsif (resource.uri != @resource_ref)
          err_arr.push I18n.t("top_container_linker.error.resources_do_not_match", :spreadsheet_resource => resource.uri, :ead_id => ead_id.to_s, :current_resource => @resource_ref, :row_num => @counter.to_s)
        end
      end
      
      #Check that the instance type exists
      instance_type = @row_hash[INSTANCE_TYPE]
      if instance_type.nil?
        err_arr.push I18n.t("top_container_linker.error.instance_type_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      #Check that either the Top Container Indicator or Top Container Record No. is present
      tc_indicator = @row_hash[TOP_CONTAINER_INDICATOR]
      tc_record_no = @row_hash[TOP_CONTAINER_ID]
      #Both missing  
      if (tc_indicator.nil? && tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      #Both exist
      if (!tc_indicator.nil? && !tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_exist", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      #Container type/Container indicator combo already exists 
      tc_type = @row_hash[TOP_CONTAINER_TYPE]
      tc_instance = nil
      if (!tc_indicator.nil? && !tc_type.nil?)
        barcode = @row_hash[TOP_CONTAINER_BARCODE]
        tc_jsonmodel_obj = @cih.get_top_container_json_from_hash(tc_type, tc_indicator, barcode, @resource_ref)
        display_indicator = tc_indicator;
        if (tc_jsonmodel_obj.nil?)
          #Create new TC 
          tc_instance = create_top_container_instance(instance_type, tc_indicator, tc_type, err_arr, ref_id, @counter.to_s)
        else
          tc_instance = create_top_container_instance(instance_type, tc_jsonmodel_obj.indicator, tc_jsonmodel_obj.type, err_arr, ref_id, @counter.to_s)
          display_indicator = tc_jsonmodel_obj.indicator
        end
Log.info( "TC INSTANCE")
Log.info(  tc_instance)
      elsif (!tc_record_no.nil?)
        tc_jsonmodel_obj = TopContainer.get_or_die(tc_record_no.strip.to_i)
        if tc_jsonmodel_obj.nil?
          #Cannot find TC record with ID
          err_arr.push I18n.t("top_container_linker.error.tc_record_no_missing", :tc_id=> tc_record_no, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        else
          child_type = @row_hash[CHILD_TYPE]
          child_indicator = @row_hash[CHILD_INDICATOR]
          barcode_2 = @row_hash[CHILD_CONTAINER_BARCODE]
          subcontainer = {}
          if (!child_type.nil? && !child_indicator.nil?)
            subcontainer = { "type_2" => child_type.strip,
                            "indicator_2" => child_indicator.strip,
                            "barcode_2" => barcode_2}
          end
          tc_instance = @cih.format_container_instance(instance_type, tc_jsonmodel_obj, subcontainer)
          display_indicator = tc_jsonmodel_obj.indicator
        end
      end
      
      if (!tc_instance.nil?)
        ao.instances ||= []
        ao.instances << tc_instance
        @report.add_info("Adding Top Container Instance " + instance_type.capitalize  + " " + display_indicator + " to Archival Object " + ref_id)
        ao_save(ao)   
      end
    rescue StopBulkImportException => se
      err_arr.join("; ")
      raise StopBulkImportException.new(se.message + "; "  + err_arr)
    rescue BulkImportException => te
      err_arr.join("; ")
      raise BulkImportException.new(te.message + "; " + err_arr)
    rescue Exception => e
      Log.error(["UNEXPLAINED EXCEPTION on process_row", e.message, e.backtrace, @row_hash].pretty_inspect)
    end
    if !err_arr.empty?
      raise BulkImportException.new(err_arr.join("; "))
    end
    ao
  end
  
  def create_top_container_instance(instance_type, indicator, type, err_arr, ref_id, row_num)
    #Find the top container with this indicator and type if it exists
    barcode = @row_hash[TOP_CONTAINER_BARCODE]
    tc_obj = @cih.get_top_container_json_from_hash(type, indicator, barcode, @resource_ref)
    #Check if the location ID can be found in the db
    child_type = @row_hash[CHILD_TYPE]
    child_indicator = @row_hash[CHILD_INDICATOR]
    barcode_2 = @row_hash[CHILD_CONTAINER_BARCODE]
    subcontainer = {}
    if (!child_type.nil? && !child_indicator.nil?)
      subcontainer = { "type_2" => child_type.strip,
                      "indicator_2" => child_indicator.strip,
                      "barcode_2" => barcode_2}
    end
 
    instance = nil
    begin
      if (!tc_obj.nil?)
        #We may have created a new TC already during the iteration so only 
        #grab the instance data from teh cih if that is the case
        instance = @cih.format_container_instance(instance_type, tc_obj, subcontainer)
      else
        instance = @cih.create_container_instance(instance_type, type, indicator, barcode, @resource_ref, @report, subcontainer)
    end
    rescue Exception => e
      @report.add_errors(I18n.t("top_container_linker.error.no_tc", :ref_id => ref_id.to_s, :row_num => row_num, :why => e.message))
      instance = nil
    end

      
    #If we created a new Top Container, then add the location and cp if they exist.
    if (tc_obj.nil? && !instance.nil?)
      #Get the top container that was just created
      tc_id = instance["sub_container"]["top_container"]["ref"].split('/')[4]
      tc_obj = TopContainer.get_or_die(tc_id.to_i)
      if (tc_obj.nil?)
        raise BulkImportException.new(I18n.t("top_container_linker.error.no_tc", :ref_id => ref_id.to_s, :row_num => row_num, :why => "Could not find newly created Top Container"))
      end
      now = Time.now
        
      #Check if the location ID can be found in the db
      loc_id = @row_hash[LOCATION_ID]
      if (!loc_id.nil?)
        loc = Location.get_or_die(loc_id.strip.to_i)
        if (loc.nil?)
          err_arr.push I18n.t("top_container_linker.error.loc_not_in_db", :loc_id=> loc_id.to_s, :ref_id => ref_id.to_s, :row_num => row_num)
        else
          begin
            loc_relationship = TopContainer.find_relationship(:top_container_housed_at)
            loc_relationship.relate(tc_obj, loc, {
              :status => 'current',
              :start_date => now.iso8601,
              :aspace_relationship_position => 0,
              :system_mtime => now,
              :user_mtime => now
            })
          rescue Exception => e
            @report.add_errors(I18n.t("top_container_linker.error.problem_adding_current_location", :ref_id => ref_id.to_s, :row_num => row_num, :why => e.message))            
            instance = nil
          end
        end
      end
      
      #Check if Container Profile Record No. can be found in the db 
      cp_id = @row_hash[CONTAINER_PROFILE_ID]
      if (!cp_id.nil?)
        cp = ContainerProfile.get_or_die(cp_id.strip.to_i)
        if (cp.nil?)
          err_arr.push I18n.t("top_container_linker.error.cp_not_in_db", :cp_id=> cp_id.to_s, :ref_id => ref_id.to_s, :row_num => row_num)
        else
          begin
            cp_relationship = TopContainer.find_relationship(:top_container_profile)
            cp_relationship.relate(tc_obj, cp, {
              :aspace_relationship_position => 1,
              :system_mtime => now,
              :user_mtime => now
            })
          rescue Exception => e
            @report.add_errors(I18n.t("top_container_linker.error.problem_setting_container_profile", :ref_id => ref_id.to_s, :row_num => row_num, :why => e.message))
            instance = nil
          end
        end
      end
    end
    
    instance
  end

end
