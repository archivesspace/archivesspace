require_relative "bulk_import_parser"

class ImportDigitalObjects < BulkImportParser
  START_MARKER = /ArchivesSpace digital object import field codes/.freeze

  def initialize(input_file, content_type, current_user, opts)
    super(input_file, content_type, current_user, opts)
    @find_uri = "/repositories/#{@opts[:repo_id]}/find_by_id/archival_objects"
    @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:id]}"
    @repo_id = @opts[:repo_id]
    @start_marker = START_MARKER  # replace down stream
  end

  def process_row
    ret_str = ""
    begin
      resource_match(@resource, @row_hash["ead"], @row_hash["res_uri"])
    rescue Exception => e
      ret_str = e.message
    end
    if ret_str.empty?
      ret_str = check_row
    end
    raise BulkImportException.new(I18n.t("bulk_import.row_error", :row => @counter, :errs => ret_str)) if !ret_str.empty?
    begin
      result = archival_object_from_ref_or_uri(@row_hash["ao_ref_id"], @row_hash["ao_uri"])
      ao = result[:ao]
      raise BulkImportException.new(I18n.t("bulk_import.error.bad_ao", errs => result[:errs])) if ao.nil?
      @report.add_archival_object(ao)
      if ao.instances
        digs = []
        ao.instances.each { |instance| digs.append(1) if instance["instance_type"] == "digital_object" }
        unless digs.empty?
          raise BulkImportException.new(I18n.t("bulk_import.row_error", :row => @counter, :errs => I18n.t("bulk_import.error.has_dig_obj")))
        end
      end
      #digital_object_id	digital_object_title	publish	digital_object_link	thumbnail

      if (dig_instance = @doh.create(@row_hash["digital_object_title"], @row_hash["thumbnail"], @row_hash["digital_object_link"], @row_hash["digital_object_id"], @row_hash["publish"], ao, @report))
        ao.instances ||= []
        ao.instances << dig_instance
        begin
          ao = ao_save(ao)
          @report.add_info(I18n.t("bulk_import.dig_assoc"))
        rescue BulkImportException => ee
          @report.add_errors(I18n.t("bulk_import.error.dig_unassoc", :msg => ee.message))
        end
      end
    end
  end

  # required fields for a digital object row: ead match, ao_ref_id and at least one of digital_object_link, thumbnail
  def check_row
    err_arr = []
    begin
      if @row_hash["ao_ref_id"].nil? && @row_hash["ao_uri"].nil?
        err_arr.push I18n.t("bulk_import.error.no_uri_or_ref")
      else
        result = archival_object_from_ref_or_uri(@row_hash["ao_ref_id"], @row_hash["ao_uri"])
        err_arr.push I18n.t("bulk_import.error.bad_ao", :errs => result[:errs]) if result[:ao].nil?
      end
      obj_link = @row_hash["digital_object_link"]
      thumb = @row_hash["thumbnail"] || @row_hash["Thumbnail"]
      err_arr.push I18n.t("bulk_import.error.dig_info_miss") if @row_hash["digital_object_link"].nil? && thumb.nil?
    end
    v = @row_hash["publish"]
    @row_hash["publish"] = (v == "1")
    err_arr.join("; ")
  end
=begin
  def initialize_info
    super
  end
=end
  def initialize_handler_enums
    @doh = DigitalObjectHandler.new(@current_user)
  end
end
