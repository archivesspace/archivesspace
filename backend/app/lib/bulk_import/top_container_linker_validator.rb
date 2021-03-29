require_relative "bulk_import_parser"

class TopContainerLinkerValidator < BulkImportParser
  include BulkImportMixins
  
  #ASpace field headers row indicator
  START_MARKER = /ArchivesSpace field code/.freeze
  
  def initialize(input_file, content_type, current_user, opts)
    super(input_file, content_type, current_user, opts, nil)
    @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:rid]}"
    @start_marker = START_MARKER
    @barcode_tc_existing_in_spreadsheet = {}
    @instance_types ||= CvList.new("instance_instance_type", @current_user) # for when we move instances over here
  end

  # look for all the required fields to make sure they are legit
  # strip all the strings and turn publish and restrictions_flag into true/false
  def process_row(row_hash = nil)
    #This allows the processing of a single row
    if (!row_hash.nil?)
      @row_hash = row_hash
    end
    err_arr = []
    begin

      # Check that the archival object ref id exists
      ref_id = @row_hash["ref_id"]
      if ref_id.nil?
        err_arr.push I18n.t("top_container_linker.error.ref_id_miss", :row_num => @counter.to_s)
        raise BulkImportException.new(err_arr.join("; "))
      else 
        #Check that the AO can be found in the db
        ao = archival_object_from_ref(ref_id.strip)
        if (ao.nil?)
          err_arr.push I18n.t("top_container_linker.error.ao_not_in_db", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      ead_id = @row_hash["ead_id"]
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
      instance_type = @row_hash["instance_type"]
      if instance_type.nil?
        err_arr.push I18n.t("top_container_linker.error.instance_type_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      retval = value_check(@instance_types, instance_type, [])
      if (retval == nil) 
        err_arr.push I18n.t("top_container_linker.error.instance_type_does_not_exist", :instance_type => instance_type, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      #Check that either the Top Container Indicator or Top Container Record No. is present
      tc_indicator = @row_hash["top_container_indicator"]
      tc_record_no = @row_hash["top_container_id"]
      #Both missing  
      if (tc_indicator.nil? && tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      #Both exist
      if (!tc_indicator.nil? && !tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_exist", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      if (!tc_record_no.nil?)
        begin
          tc_obj = TopContainer.get_or_die(tc_record_no.strip.to_i)
        rescue NotFoundException
          tc_obj = nil
        end
        if tc_obj.nil?
          #Cannot find TC record with ID
          err_arr.push I18n.t("top_container_linker.error.tc_record_no_missing", :tc_id=> tc_record_no, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      #Container type/Container indicator combo already exists 
      tc_type = @row_hash["top_container_type"]
      if (!tc_indicator.nil? && !tc_type.nil?)
        type_id = BackendEnumSource.id_for_value("container_type",tc_type.strip)
        tc_exists = indicator_and_type_exist_for_resource?(ead_id, tc_indicator, type_id)
        if (tc_exists)
          err_arr.push I18n.t("top_container_linker.error.tc_ind_ct_exists", :indicator=> tc_indicator, :tc_type=> tc_type, :ead_id => ead_id, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      #Check if the barcode already exists in the db (fail if so)
      barcode = @row_hash["top_container_barcode"]
      if (!barcode.nil?)
        tc_obj = find_top_container({:barcode => barcode.strip})
        if (!tc_obj.nil?)
          err_arr.push I18n.t("top_container_linker.error.tc_barcode_exists", :barcode=> barcode, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        elsif barcode_differs_from_prev_tc?(tc_indicator, tc_type, barcode)
          err_arr.push I18n.t("top_container_linker.error.tc_barcode_differs", :barcode=> barcode, :type=>tc_type, :indicator=> tc_indicator, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        else
          add_tc_bc(tc_indicator, tc_type, barcode)
        end
      end
      
      
      #Check if the barcode_2 already exists in the db (fail if so).  
      #This will be put in place when Harvard's code is merged
      barcode_2 = @row_hash["child_barcode"]
      child_type = @row_hash["child_type"]
      child_indicator = @row_hash["child_indicator"]
      if (!barcode_2.nil?)
        sc_obj = sub_container_from_barcode(barcode_2.strip)
        if (!sc_obj.nil?)
          err_arr.push I18n.t("top_container_linker.error.sc_barcode_exists", :barcode=> barcode_2, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        elsif (!child_type.nil? && !child_indicator.nil?)
          if barcode_differs_from_prev_tc?(child_indicator, child_type, barcode_2, true)
            err_arr.push I18n.t("top_container_linker.error.sc_barcode_differs", :barcode=> barcode_2, :type=>child_type, :indicator=>child_indicator, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
          end
          add_tc_bc(child_indicator, child_type, barcode_2, true)
        end
      end
      
      #Check if the location ID can be found in the db
      loc_id = @row_hash["location_id"]
      if (!loc_id.nil?)
        begin
          loc = Location.get_or_die(loc_id.strip.to_i)
        rescue NotFoundException
          loc = nil
        end
        if (loc.nil?)
          err_arr.push I18n.t("top_container_linker.error.loc_not_in_db", :loc_id=> loc_id.to_s, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      #Check if Container Profile Record No. can be found in the db 
      cp_id = @row_hash["container_profile_id"]
      if (!cp_id.nil?)
        begin
          cp = ContainerProfile.get_or_die(cp_id.strip.to_i)
        rescue NotFoundException
          cp = nil
        end
        if (cp.nil?)
          err_arr.push I18n.t("top_container_linker.error.cp_not_in_db", :cp_id=> cp_id.to_s, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
    rescue Exception => e
      Log.error(["UNEXPLAINED EXCEPTION on check row", e.message, e.backtrace, @row_hash].pretty_inspect)
        raise
    end
    if !err_arr.empty?
      raise BulkImportException.new(err_arr.join("; "))
    end
  end
  
  def get_hash_table()
    @barcode_tc_existing_in_spreadsheet
  end
  
  private
  
  def add_tc_bc(indicator, type, barcode, is_child=false)
    key = "#{type} #{indicator}"
    key += " child" if is_child
    @barcode_tc_existing_in_spreadsheet[key] = barcode
  end
  
  #Checks to see if the barcode for subsequent indicator-type combos
  #are the same
  def barcode_differs_from_prev_tc?(indicator, type, barcode, is_child=false)
    key = "#{type} #{indicator}"
    key += " child" if is_child
    @barcode_tc_existing_in_spreadsheet[key] && @barcode_tc_existing_in_spreadsheet[key] != barcode    
  end

end
