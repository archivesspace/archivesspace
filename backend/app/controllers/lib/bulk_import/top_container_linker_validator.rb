require_relative "bulk_import_spreadsheet_parser"

class TopContainerLinkerValidator < BulkImportSpreadsheetParser
  def validate
    begin
      initialize_info
      validate_spreadsheet_data
      
#      @counter = 0
#      begin
#        while (row = @rows.next)
#          @counter += 1
#          values = row_values(row)
#          next if values.reject(&:nil?).empty?
#          @row_hash = Hash[@headers.zip(values)]
#          ao = nil
#          begin
#            @report.new_row(@counter)
#            ao = process_row
#            @rows_processed += 1
#            @error_level = nil
#          rescue StopTopContainerLinkingException => se
#            @report.add_errors(I18n.t("bulk_import.error.stopped", :row => @counter, :msg => se.message))
#            raise StopIteration.new
#          rescue TopContainerLinkerException => e
#            @error_rows += 1
#            @report.add_errors(e.message)
#            @error_level = @hier
#          end
#          @report.end_row
#        end
#      rescue StopIteration
#        # we just want to catch this without processing further
#      end
#      if @rows_processed == 0
#        raise TopContainerLinkerException.new(I18n.t("bulk_import.error.no_data"))
#      end
#    rescue Exception => e
#      if e.is_a?(TopContainerLinkerException) || e.is_a?(StopTopContainerLinkingException)
#        @report.add_terminal_error(I18n.t("bulk_import.error.excel", :errs => e.message), @counter)
#      elsif e.is_a?(StopIteration) && @headers.nil?
#        @report.add_terminal_error(I18n.t("bulk_import.error.no_header"), @counter)
#      else # something else went wrong
#        @report.add_terminal_error(I18n.t("bulk_import.error.system", :msg => e.message), @counter)
#        Log.error("UNEXPECTED EXCEPTION on bulkimport load! #{e.message}")
#        Log.error(e.backtrace.pretty_inspect)
#      end
    end
    return @report
  end
  
  
  def initialize(input_file, file_content_type, opts = {}, current_user)
    super(input_file, file_content_type, opts = {}, current_user)
  end

  
  #We first want to validate spreadsheet data to make sure that the
  #required fields exist as well as verify that the populated fields
  #have valid data
  def validate_spreadsheet_data
    begin
      while (row = @rows.next)
        @counter += 1
        #values = row_values(row)
        #next if values.reject(&:nil?).empty?
        row_hash = get_row_hash(row)
        begin
          @report.new_row(@counter)
          errors = check_row(row_hash)
          Log.error("ERRORS")
          Log.error(errors)
          if !errors.empty?
            Log.error('ADDING ERRORS AND STOPPING ITERATION')
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


  # save (create/update) the archival object, then revive it

#  def ao_save(ao)
#    revived = nil
#    begin
#      archObj = nil
#      if ao.id.nil?
#        raise TopContainerLinkerException.new(I18n.t("top_container_linker.error.ao_does_not_exist")
#      else
#        obj = ArchivalObject.get_or_die(ao.id)
#        archObj = obj.update_from_json(ao)
#      end
#      objs = ArchivalObject.sequel_to_jsonmodel([archObj])
#      revived = objs[0] if !objs.empty?
#    rescue ValidationException => ve
#      raise TopContainerLinkerException.new(I18n.t("bulk_import.error.ao_validation", :err => ve.errors))
#    rescue Exception => e
#      Log.error("UNEXPECTED ao save error: #{e.message}\n#{e.backtrace}")
#      Log.error(ASUtils.jsonmodels_to_hashes(ao).pretty_inspect) if ao
#      raise e
#    end
#    revived
#  end

  # look for all the required fields to make sure they are legit
  # strip all the strings and turn publish and restrictions_flaginto true/false
  def check_row(row_hash)
    err_arr = []
    begin
      # Check that the archival object ref id exists
      ref_id = row_hash["Ref ID"]
      if ref_id.nil?
        err_arr.push I18n.t("top_container_linker.error.ref_id_miss", :row_num => @counter.to_s)
      else 
        #Check that the AO can be found in the db
        ao = archival_object_from_ref(ref_id.strip)
        if (ao.nil?)
          err_arr.push I18n.t("top_container_linker.error.ao_not_in_db", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
     
      #Check that the instance type exists
      instance_type = row_hash["Instance Type"]
      if instance_type.nil?
        err_arr.push I18n.t("top_container_linker.error.instance_type_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      #Check that either the Top Container Indicator or Top Container Record No. is present
      tc_indicator = row_hash["Top Container Indicator"]
      tc_record_no = row_hash["Top Container Record No."]
      #Both missing  
      if (tc_indicator.nil? && tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_miss", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      #Both exist
      if (!tc_indicator.nil? && !tc_record_no.nil?)
        err_arr.push I18n.t("top_container_linker.error.tc_indicator_and_record_no_exist", :ref_id => ref_id.to_s, :row_num => @counter.to_s)
      end
      
      #Container type/Container indicator combo already exists 
      tc_type = row_hash["Top Container Type"]
      if (!tc_indicator.nil? && !tc_type.nil?)
        type_id = BackendEnumSource.id_for_value("container_type",tc_type.strip)
        tc_obj = find_top_container({:indicator => tc_indicator, :type_id => type_id})
        if (!tc_obj.nil?)
          err_arr.push I18n.t("top_container_linker.error.tc_ind_ct_exists", :indicator=> tc_indicator, :tc_type=> tc_type, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
          
      #Check if the barcode already exists in the db (fail if so)
      barcode = row_hash["Top Container Barcode"]
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
      loc_id = row_hash["Location Record No"]
      if (!loc_id.nil?)
        loc = Location.get_or_die(loc_id.strip)
        if (loc.nil?)
          err_arr.push I18n.t("top_container_linker.error.loc_not_in_db", :loc_id=> loc_id.to_s, :ref_id => ref_id.to_s, :row_num => @counter.to_s)
        end
      end
      
      #Check if Container Profile Record No. can be found in the db 
      cp_id = row_hash["Container Profile Record No."]
      if (!cp_id.nil?)
        cp = ContainerProfile.get_or_die(cp_id.strip)
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


  # Link an archival_object
#  def link_archival_object(parent_uri)
#    ao = JSONModel(:archival_object).find(aoid, find_opts) 
#    ao.instances = create_top_container_instances
#    ao
#  end


#  def create_top_container_instances
#    instances = []
#    cntr = 1
#    substr = ""
#    until @row_hash["cont_instance_type#{substr}"].nil? && @row_hash["type_1#{substr}"].nil? && @row_hash["barcode#{substr}"].nil?
#      begin
#        subcont = { "type_2" => @row_hash["type_2#{substr}"],
#                    "indicator_2" => @row_hash["indicator_2#{substr}"]}
#
#        instance = @cih.create_container_instance(@row_hash["cont_instance_type#{substr}"],
#                                                  @row_hash["type_1#{substr}"], @row_hash["indicator_1#{substr}"], @row_hash["barcode#{substr}"], @resource["uri"], @report, subcont)
#      rescue Exception => e
#        @report.add_errors(I18n.t("bulk_import.error.no_tc", number: cntr.to_s, why: e.message))
#        instance = nil
#      end
#      cntr += 1
#      substr = "_#{cntr}"
#      instances << instance if instance
#    end
#    return instances
#  end




#  def process_row
#    begin
#      ao = link_archival_object
#    rescue JSONModel::ValidationException => ve
#      # ao won't have been linked
#      msg = I18n.t("bulk_import.error.second_save_error", :what => ve.errors, :title => ao.title, :pos => ao.position)
#      @report.add_errors(msg)
#    rescue Exception => e
#      Log.error("UNEXPECTED ON SECOND SAVE#{e.message}")
#      Log.error(e.backtrace.pretty_inspect)
#      Log.error(ASUtils.jsonmodels_to_hashes(ao).pretty_inspect)
#      raise TopContainerLinkerException.new(e.message)
#    end
#    @report.add_archival_object(ao) if !ao.nil?
#    @updated_ao_refs.push ao.uri
#  end

end
