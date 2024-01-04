require_relative "bulk_import_parser"

class ImportDigitalObjects < BulkImportParser
  START_MARKER = /ArchivesSpace digital object import field codes/.freeze

  def initialize(input_file, content_type, current_user, opts, log_method = nil)
    super(input_file, content_type, current_user, opts, log_method)
    @find_uri = "/repositories/#{@opts[:repo_id]}/find_by_id/archival_objects"
    @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:id]}"
    @repo_id = @opts[:repo_id]
    @start_marker = START_MARKER  # replace down stream
  end

  def create_instance(ao)
    dig_instance = nil
    begin
      normalize_publish_column(@row_hash, 'digital_object_publish')
      normalize_publish_column(@row_hash, 'nonrep_publish')
      dig_instance = @doh.create(
        @row_hash["digital_object_title"],
        @row_hash["digital_object_id"],
        @row_hash["digital_object_publish"],
        ao,
        @report,
        representative_file_version,
        non_representative_file_version)
    rescue Exception => e
      @report.add_errors(e.message)
    end
    if dig_instance && !@validate_only # only try to save if not validate only
      ao.instances ||= []
      ao.instances << dig_instance
      begin
        ao = ao_save(ao)
        @report.add_info(I18n.t("bulk_import.dig_assoc"))
      rescue BulkImportException => ee
        @report.add_errors(I18n.t("bulk_import.error.dig_unassoc", :msg => ee.message))
      end
    end
    dig_instance
  end

  def process_row
    errs = []
    begin
      resource_match(@resource, @row_hash["ead"], @row_hash["res_uri"])
    rescue Exception => e
      errs << e.message
    end
    errs << check_row
    errs.reject!(&:empty?)
    if !@validate_only && !errs.empty?
      err = errs.join("; ")
      raise BulkImportException.new(I18n.t("bulk_import.row_error", :row => @counter, :errs => err))
    end
    ao = verify_ao(@row_hash["ao_ref_id"], @row_hash["ao_uri"], errs)
    if ao.nil? && !@validate_only
      err = errs.join("; ")
      raise BulkImportException.new(I18n.t("bulk_import.error.bad_ao", :errs => err))
    end
    digital_instance = create_instance(ao)
    if !digital_instance & @validate_only
      @report.add_errors(errs.join("; ")) if !errs.empty?
      @report.add_errors(I18n.t("bulk_import.object_not_created_be", :what => I18n.t("bulk_import.dig")))
    elsif !errs.empty?
      err = errs.join("; ")
      @report.add_errors(I18n.t("bulk_import.error.dig_unassoc", :msg => err))
    end
    @created_refs.concat(
      [ao.uri, digital_instance.digital_object['ref']]
    ) if ao && digital_instance && !@validate_only
    digital_instance
  end

  def log_row(row)
    unless row.archival_object_id.nil?
      log_obj = I18n.t("bulk_import.log_obj", :what => I18n.t("bulk_import.ao"), :nm => row.archival_object_display, :id => row.archival_object_id, :ref_id => row.ref_id)
      @log_method.call(I18n.t("bulk_import.log_info", :row => row.row, :what => log_obj))
    end
    unless row.info.empty?
      row.info.each do |info|
        @log_method.call(I18n.t("bulk_import.log_info", :row => row.row, :what => info))
      end
    end
    unless row.errors.empty?
      row.errors.each do |err|
        @log_method.call(I18n.t("bulk_import.log_error", :row => row.row, :what => err))
      end
    end
  end

  # required fields for a digital object row: ead match, (ao_ref_id  or ao_uri)
  def check_row
    err_arr = []
    begin
      if @row_hash["ao_ref_id"].nil? && @row_hash["ao_uri"].nil?
        err_arr.push I18n.t("bulk_import.error.no_uri_or_ref")
      end
    end
    normalize_publish_column(@row_hash)
    normalize_publish_column(@row_hash, 'digital_object_link_publish')
    normalize_publish_column(@row_hash, 'thumbnail_publish')
    err_arr.join("; ")
  end

  def initialize_handler_enums
    @doh = DigitalObjectHandler.new(@current_user, @validate_only)
  end

  # any problem here would result in the digital object not being created
  def verify_ao(ref_id, uri, errs)
    result = archival_object_from_ref_or_uri(ref_id, uri)
    ao = result[:ao]
    if ao.nil?
      errs << I18n.t("bulk_import.error.bad_ao", :errs => result[:errs])
    else
      @report.add_archival_object(ao)
    end
    ao
  end

end
