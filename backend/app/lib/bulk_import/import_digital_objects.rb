require_relative "bulk_import_parser"

class ImportDigitalObjects < BulkImportParser
  START_MARKER = /ArchivesSpace digital object import field codes/.freeze

  def initialize(input_file, content_type, current_user, opts, log_method = nil)
    super(input_file, content_type, current_user, opts, log_method)

    @find_uri = "/repositories/#{@opts[:repo_id]}/find_by_id/archival_objects"
    @resource_ref = "/repositories/#{@opts[:repo_id]}/resources/#{@opts[:id]}"
    @repo_id = @opts[:repo_id]
    @start_marker = START_MARKER  # replace down stream
    @date_types = CvList.new("date_type", @current_user)
    @date_labels = CvList.new("date_label", @current_user)
    @date_certainty = CvList.new("date_certainty", @current_user)
    @extent_types = CvList.new("extent_extent_type", @current_user)
    @extent_portions = CvList.new("extent_portion", @current_user)
  end

  def create_instance(ao)
    dig_instance = nil

    @notes_handler = NotesHandler.new
    @agent_handler = AgentHandler.new(@current_user, @validate_only)
    @subject_handler = SubjectHandler.new(@current_user, @validate_only)

    begin
      normalize_boolean_column(@row_hash, 'digital_object_publish')
      normalize_boolean_column(@row_hash, 'restrictions')
      normalize_boolean_column(@row_hash, 'nonrep_publish')
      dates = create_dates
      notes = create_notes
      extents = process_extents
      subjects = process_subjects
      linked_agents = process_agents

      dig_instance = @digital_object_handler.create(
        @row_hash["digital_object_title"],
        @row_hash["digital_object_id"],
        @row_hash["digital_object_publish"],
        @row_hash["level"],
        @row_hash["digital_object_type"],
        @row_hash["restrictions"],
        dates,
        notes,
        extents,
        subjects,
        linked_agents,
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
    normalize_boolean_column(@row_hash, 'publish')
    normalize_boolean_column(@row_hash, 'digital_object_link_publish')
    normalize_boolean_column(@row_hash, 'thumbnail_publish')
    err_arr.join("; ")
  end

  def initialize_handler_enums
    @digital_object_handler = DigitalObjectHandler.new(@current_user, @validate_only)
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

  private

  def create_dates
    dates = []

    counter = 1
    column_counter = ""
    until [@row_hash["begin#{column_counter}"], @row_hash["end#{column_counter}"], @row_hash["expression#{column_counter}"]].reject(&:nil?).empty?
      date = create_date(
        @row_hash["dates_label#{column_counter}"],
        @row_hash["begin#{column_counter}"],
        @row_hash["end#{column_counter}"],
        @row_hash["date_type#{column_counter}"],
        @row_hash["expression#{column_counter}"],
        @row_hash["date_certainty#{column_counter}"]
      )
      dates << date if date
      counter += 1
      column_counter = "_#{counter}"
    end

    dates
  end

  def create_notes
    notes = []

    counter = 1
    column_counter = ""
    until [@row_hash["note_type#{column_counter}"], @row_hash["note_label#{column_counter}"], @row_hash["note_publish#{column_counter}"]].reject(&:nil?).empty?
      note = @notes_handler.create_note(
        @row_hash["note_type#{column_counter}"],
        @row_hash["note_label#{column_counter}"],
        @row_hash["note_content#{column_counter}"],
        normalize_boolean_column(@row_hash, "note_publish#{column_counter}"),
        true
      )
      notes << note if note
      counter += 1
      column_counter = "_#{counter}"
    end

    notes
  end

  def process_agents
    agent_links = []

    %w(people corporate_entities families).each do |type|
      num = 1
      while true
        id_key = "#{type}_agent_record_id_#{num}"
        header_key = "#{type}_agent_header_#{num}"

        break if @row_hash[id_key].nil? && @row_hash[header_key].nil?

        link = nil
        begin
          link = @agent_handler.get_or_create(
            type,
            @row_hash[id_key],
            @row_hash[header_key],
            @row_hash["#{type}_agent_relator_#{num}"],
            @row_hash["#{type}_agent_role_#{num}"], @report
          )

          agent_links.push link if link && !@validate_only

        rescue BulkImportException => e
          @report.add_errors(I18n.t("bulk_import.error.process_error", :type => "#{type} Agent", :num => num, :why => e.message))
        end
        num += 1
      end
    end

    agent_links
  end

  def process_subjects
    subjects = []

    repo_id = @repository.split("/")[2]
    (1..10).each do |num|
      unless @row_hash["subject_#{num}_record_id"].nil? && @row_hash["subject_#{num}_term"].nil?
        subj = nil
        begin
          subj = @subject_handler.get_or_create(
            @row_hash["subject_#{num}_record_id"],
            @row_hash["subject_#{num}_term"], @row_hash["subject_#{num}_type"],
            @row_hash["subject_#{num}_source"], repo_id, @report
          )

          subjects.push subj if subj

        rescue Exception => e
          @report.add_errors(I18n.t("bulk_import.error.process_error", :type => "Subject", :num => num, :why => e.message))
        end
      end
    end

    subjects
  end

  def process_extents
    extents = []

    counter = 1
    column_counter = ""
    until @row_hash["number#{column_counter}"].nil? && @row_hash["extent_type#{column_counter}"].nil?
      extent = create_extent(column_counter)
      extents << extent if extent
      counter += 1
      column_counter = "_#{counter}"
    end

    extents
  end

  def create_extent(substr)
    ext_str = "Extent: #{@row_hash["portion#{substr}"] || "whole"} #{@row_hash["number#{substr}"]} #{@row_hash["extent_type#{substr}"]} #{@row_hash["container_summary#{substr}"]} #{@row_hash["physical_details#{substr}"]} #{@row_hash["dimensions#{substr}"]}"
    errs = []
    portion = value_check(@extent_portions, (@row_hash["portion#{substr}"] || "whole"), errs)
    type = value_check(@extent_types, @row_hash["extent_type#{substr}"], errs)

    extent = { "portion" => portion,
               "extent_type" => type }
    %w(number container_summary physical_details dimensions).each do |w|
      extent[w] = @row_hash["#{w}#{substr}"] || nil
    end
    if errs.empty?
      begin
        ex = JSONModel(:extent).new(extent)
        return ex if test_exceptions(ex, "Extent")
      rescue Exception => e
        @report.add_errors(I18n.t("bulk_import.error.extent_validation", :msg => e.message, :ext => ext_str))
      end
    else
      @report.add_errors(I18n.t("bulk_import.error.extent_validation", :msg => errs.join(" ,"), :ext => ext_str))
    end
    return nil
  end
end
