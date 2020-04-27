require_relative "bulk_import_parser"
require_relative "top_container_linker_mixins"

class TopContainerLinkerValidator < BulkImportParser
  
  #ASpace field headers row indicator
  START_MARKER = /ArchivesSpace field code (please don't edit this row)/.freeze
   
  def validate
    begin
      initialize_info
      validate_spreadsheet_data
    end
    return @report
  end
  
  
#  def initialize(input_file, content_type, current_user, opts)
#    super(input_file, content_type, current_user, opts)
#  end

  
  #We first want to validate spreadsheet data to make sure that the
  #required fields exist as well as verify that the populated fields
  #have valid data
  def validate_spreadsheet_data
    begin
      while (row = @rows.next)
        @counter += 1
        row_hash = get_row_hash(row)
        begin
          @report.new_row(@counter)
          errors = process_row
          if !errors.empty?
            @report.add_errors(errors)
            @error_rows += 1
            @report.end_row
            raise StopIteration.new
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
    end
    if @error_rows > 0
      errors = []
      @report.rows.each do |error_row| 
        errors << error_row.errors.join(", ")
      end
      raise TopContainerLinkerException.new(errors.join(', '))
    end
    if @rows_processed == 0
      raise TopContainerLinkerException.new(I18n.t("bulk_import.error.no_data"))
    end
    
  end


  # look for all the required fields to make sure they are legit
  # strip all the strings and turn publish and restrictions_flaginto true/false
  def process_row
    err_arr = []
    begin
              
      # Check that the archival object ref id exists
      ref_id = row_hash[REF_ID]
      if ref_id.nil?
        err_arr.push I18n.t("top_container_linker.error.ref_id_miss", :row_num => @counter.to_s)
        #REturn here because this is the most critical and the other error messages rely on it.
        return  err_arr.join("; ")
      else 
        #Check that the AO can be found in the db
        ao = archival_object_from_ref(ref_id.strip)
        if (ao.nil?)
          err_arr.push I18n.t("top_container_linker.error.ao_not_in_db", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      ead_id = row_hash[EAD_ID]
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
      tc_type = row_hash[TOP_CONTAINER_TYPE]
      if (!tc_indicator.nil? && !tc_type.nil?)
        type_id = BackendEnumSource.id_for_value("container_type",tc_type.strip)
        tc_obj = find_top_container({:indicator => tc_indicator, :type_id => type_id})
        if (!tc_obj.nil?)
          err_arr.push I18n.t("top_container_linker.error.tc_ind_ct_exists", :indicator=> tc_indicator, :tc_type=> tc_type, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
          
      #Check if the barcode already exists in the db (fail if so)
      barcode = row_hash[TOP_CONTAINER_BARCODE]
      if (!barcode.nil?)
        tc_obj = find_top_container({:barcode => barcode.strip})
        if (!tc_obj.nil?)
          err_arr.push I18n.t("top_container_linker.error.tc_barcode_exists", :barcode=> barcode, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      #Check if the barcode_2 already exists in the db (fail if so).  
      #This will be put in place when Harvard's code is merged
      #barcode_2 = row_hash["Child Barcode"]
      #if (!barcode_2.empty?)
        #sc_obj = sub_container_from_barcode(barcode_2.strip)
        #if (sc_obj)
        #  err_arr.push I18n.t("top_container_linker.error.sc_barcode_exists", :barcode=> barcode_2, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        #end
      #end
      
      #Check if the location ID can be found in the db
      loc_id = row_hash[LOCATION_ID]
      if (!loc_id.nil?)
        begin
          loc = Location.get_or_die(loc_id.strip)
        rescue NotFoundException
          loc = nil
        end
        if (loc.nil?)
          err_arr.push I18n.t("top_container_linker.error.loc_not_in_db", :loc_id=> loc_id.to_s, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      #Check if Container Profile Record No. can be found in the db 
      cp_id = row_hash[CONTAINER_PROFILE_ID]
      if (!cp_id.nil?)
        begin
          cp = ContainerProfile.get_or_die(cp_id.strip)
        rescue NotFoundException
          cp = nil
        end
        if (cp.nil?)
          err_arr.push I18n.t("top_container_linker.error.cp_not_in_db", :cp_id=> cp_id.to_s, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
            
      
    rescue StopTopContainerLinkingException => se
      raise
    rescue Exception => e
      Log.error(["UNEXPLAINED EXCEPTION on check row", e.message, e.backtrace, row_hash].pretty_inspect)
        raise
    end
    err_arr.join("; ")
  end

end
