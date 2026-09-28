require_relative "bulk_import_parser"
require_relative "row_field_builders"
require_relative "../../converters/lib/utils"
require "bigdecimal"

class ImportDigitalObjects < BulkImportParser
  include RowFieldBuilders

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
    @lang_handler = LangHandler.new(@current_user)

    begin
      publish = digital_object_boolean('digital_object_publish')
      restrictions = digital_object_boolean('restrictions')
      dates = create_dates
      notes = create_notes
      extents = process_extents
      subjects = process_subjects
      linked_agents = process_agents

      dig_instance = @digital_object_handler.create(
        title: @row_hash["digital_object_title"],
        id: @row_hash["digital_object_id"],
        publish: publish,
        level: @row_hash["level"],
        digital_object_type: @row_hash["digital_object_type"],
        restrictions: restrictions,
        dates: dates,
        notes: notes,
        extents: extents,
        subjects: subjects,
        linked_agents: linked_agents,
        archival_object: ao,
        report: @report,
        file_versions: file_versions,
        lang_materials: create_lang_materials,
        user_defined: create_user_defined,
        collection_management: create_collection_management)
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

  def file_versions
    groups = @row_hash.keys
      .grep(/\Afile_version_\d+_.+\z/)
      .group_by { |key| key[/\Afile_version_(\d+)_/, 1] }

    groups.keys.sort_by(&:to_i).filter_map do |index|
      keys = groups[index]
      next if keys.all? { |key| @row_hash[key].nil? }

      fv = {}
      keys.each do |key|
        field = key.sub(/\Afile_version_\d+_/, "")
        fv[field.to_sym] = @row_hash[key]
      end

      representative_column = "file_version_#{index}_is_representative"
      publish_column = "file_version_#{index}_publish"
      fv[:is_representative] = digital_object_boolean(representative_column) if keys.include?(representative_column)
      fv[:publish] = digital_object_boolean(publish_column) if keys.include?(publish_column)

      fv[:publish] = true if fv[:is_representative]
      size_column = "file_version_#{index}_file_size_bytes"
      fv[:file_size_bytes] = file_version_file_size_bytes(size_column, fv[:file_size_bytes])
      fv
    end
  end

  private

  def digital_object_boolean(column)
    ASpaceImport::Utils.normalize_boolean.call(@row_hash[column])
  rescue ASpaceImport::Utils::UnrecognizedBooleanValue => e
    raise BulkImportException.new(I18n.t("bulk_import.error.unrecognized_boolean", :column => column, :value => e.value))
  end

  def file_version_file_size_bytes(column, value)
    return nil if value.nil?

    integer = exact_whole_number(value)
    return integer unless integer.nil?

    raise BulkImportException.new(
      I18n.t(
        "bulk_import.error.invalid_file_version_size",
        :column => column,
        :value => value
      )
    )
  end

  def valid_column_codes
    @valid_column_codes ||= CSV.read(
      File.join(File.dirname(__FILE__), "..", "templates", "bulk_import_DO_template.csv")
    ).first
  end

  # This importer's repeatable root namespaces. Exact accepted leaves remain
  # the maintained CSV via valid_column_codes; Language Material keeps its
  # fixed language_and_script segment. The Agent pattern captures only the
  # outer agent_N_ index.
  def structural_column_rules
    [
      { :namespace => "file_version" },
      { :namespace => "lang_material", :fixed_segment => "language_and_script" },
      { :namespace => "subject" },
      { :namespace => "date" },
      { :namespace => "note" },
      { :namespace => "agent" },
      { :namespace => "extent" },
    ].map do |family|
      infix = family[:fixed_segment] ? "_#{family[:fixed_segment]}_" : "_"
      {
        :pattern => /\A#{Regexp.escape(family[:namespace])}_(?<index>[1-9]\d*)#{infix}.+\z/,
        :representative => "1",
      }
    end
  end

  def canonical_group_indices(namespace)
    pattern = /\A#{Regexp.escape(namespace)}_([1-9]\d*)_/
    @row_hash.keys.grep(pattern).map { |key| key[pattern, 1] }.uniq.sort_by(&:to_i)
  end

  def create_lang_materials
    lang_materials = []
    canonical_group_indices("lang_material").each do |index|
      language = @row_hash["lang_material_#{index}_language_and_script_language"]
      script = @row_hash["lang_material_#{index}_language_and_script_script"]
      next if language.nil? && script.nil?

      lang_materials.concat(
        @lang_handler.create_language(
          language || "",
          script,
          nil, nil, @report
        )
      )
    end
    lang_materials
  end

  def create_collection_management
    cm = {}
    @row_hash.keys.grep(/\Acollection_management_/).each do |col|
      value = @row_hash[col]
      next if value.nil?

      field = col.sub(/\Acollection_management_/, "")
      cm[field] =
        if field == "rights_determined"
          digital_object_boolean(col)
        else
          value
        end
    end
    return nil if cm.empty?

    cm["jsonmodel_type"] = "collection_management"
    cm
  end

  def create_user_defined
    ud = {}
    @row_hash.keys.grep(/\Auser_defined_/).each do |col|
      value = @row_hash[col]
      next if value.nil?

      field = col.sub(/\Auser_defined_/, "")
      ud[field] =
        if %w[boolean_1 boolean_2 boolean_3].include?(field)
          digital_object_boolean(col)
        elsif field.start_with?("integer_")
          normalize_user_defined_integer(value)
        elsif field.start_with?("real_")
          normalize_user_defined_real(value)
        else
          value
        end
    end
    return nil if ud.empty?

    ud["jsonmodel_type"] = "user_defined"
    ud
  end

  def create_dates
    dates = []

    canonical_group_indices("date").each do |index|
      label = @row_hash["date_#{index}_label"]
      date_begin = @row_hash["date_#{index}_begin"]
      date_end = @row_hash["date_#{index}_end"]
      date_type = @row_hash["date_#{index}_date_type"]
      expression = @row_hash["date_#{index}_expression"]
      certainty = @row_hash["date_#{index}_certainty"]
      next if [label, date_begin, date_end, date_type, expression, certainty].all?(&:nil?)

      date = create_date(label, date_begin, date_end, date_type, expression, certainty)
      dates << date if date
    end

    dates
  end

  def create_notes
    notes = []

    canonical_group_indices("note").each do |index|
      type = @row_hash["note_#{index}_type"]
      label = @row_hash["note_#{index}_label"]
      content = @row_hash["note_#{index}_content"]
      publish_column = "note_#{index}_publish"
      next if [type, label, @row_hash[publish_column], content].all?(&:nil?)

      note = @notes_handler.create_note(
        type,
        label,
        content,
        digital_object_boolean(publish_column),
        true
      )
      notes << note if note
    end

    notes
  end

  def process_agents
    agent_links = []

    canonical_group_indices("agent").each do |num|
      agent_type = @row_hash["agent_#{num}_agent_type"]
      record_id = @row_hash["agent_#{num}_record_id"]
      header = @row_hash["agent_#{num}_header"]
      role = @row_hash["agent_#{num}_role"]
      relator = @row_hash["agent_#{num}_relator"]
      next if [agent_type, record_id, header, role, relator].all?(&:nil?)

      if record_id.nil? && header.nil?
        @report.add_errors(I18n.t("bulk_import.error.agent_missing_identity", :num => num))
        next
      end

      if agent_type.nil?
        @report.add_errors(I18n.t("bulk_import.error.agent_missing_type", :num => num))
        next
      end

      type = handler_agent_type(agent_type)
      if type.nil?
        @report.add_errors(I18n.t("bulk_import.error.agent_unsupported_type", :num => num, :agent_type => agent_type))
        next
      end

      begin
        link = @agent_handler.get_or_create(
          type,
          record_id,
          header,
          relator,
          role, @report
        )

        agent_links.push link if link && !@validate_only

      rescue BulkImportException => e
        @report.add_errors(I18n.t("bulk_import.error.process_error", :type => I18n.t("bulk_import.agent"), :num => num, :why => e.message))
      end
    end

    agent_links
  end

  def handler_agent_type(agent_type)
    case agent_type
    when "agent_person"
      "people"
    when "agent_family"
      "families"
    when "agent_corporate_entity"
      "corporate_entities"
    end
  end

  def process_subjects
    subjects = []

    repo_id = @repository.split("/")[2]
    canonical_group_indices("subject").each do |num|
      record_id = @row_hash["subject_#{num}_record_id"]
      term = @row_hash["subject_#{num}_term"]
      type = @row_hash["subject_#{num}_type"]
      source = @row_hash["subject_#{num}_source"]
      next if [record_id, term, type, source].all?(&:nil?)

      if record_id.nil? && term.nil?
        @report.add_errors(I18n.t("bulk_import.error.subject_missing_identity", :num => num))
        next
      end

      begin
        subj = @subject_handler.get_or_create(
          record_id, term, type, source, repo_id, @report
        )

        subjects.push subj if subj

      rescue Exception => e
        @report.add_errors(I18n.t("bulk_import.error.process_error", :type => "Subject", :num => num, :why => e.message))
      end
    end

    subjects
  end

  def normalize_user_defined_integer(value)
    integer = exact_whole_number(value)
    return integer.to_s unless integer.nil?

    raise BulkImportException.new(I18n.t("bulk_import.error.invalid_user_defined_integer", :value => value))
  end

  def exact_whole_number(value)
    # JRuby Integer() truncates Floats, so 42.5 becomes 42. Those values use
    # the decimal exactness check below instead of that shortcut.
    unless value.is_a?(Float)
      integer = Integer(value, exception: false)
      return integer unless integer.nil?
    end

    decimal = decimal_from(value)
    return nil unless decimal&.finite? && decimal.frac.zero?

    decimal.to_i
  rescue FloatDomainError
    nil
  end

  def normalize_user_defined_real(value)
    float = Float(value, exception: false)
    decimal = decimal_from(value)
    unless float&.finite? && decimal&.finite? && (decimal * 100_000).frac.zero?
      raise BulkImportException.new(I18n.t("bulk_import.error.invalid_user_defined_real", :value => value))
    end

    integer, fraction = decimal.to_s("F").split(".", 2)
    raise BulkImportException.new(I18n.t("bulk_import.error.invalid_user_defined_real", :value => value)) if integer.delete_prefix("-").length > 9

    return integer if fraction.nil?

    "#{integer}.#{fraction.sub(/0+\z/, "")}".sub(/\.\z/, "")
  end

  def decimal_from(value)
    BigDecimal(value.to_s)
  rescue ArgumentError
    nil
  end

  def process_extents
    extents = []

    canonical_group_indices("extent").each do |index|
      next if @row_hash.none? { |key, value| key.is_a?(String) && key.start_with?("extent_#{index}_") && !value.nil? }

      extent = create_extent(index)
      extents << extent if extent
    end

    extents
  end

  def extent_cell(index, leaf)
    @row_hash["extent_#{index}_#{leaf}"]
  end

  def create_extent(index)
    portion_cell = extent_cell(index, "portion")
    number_cell = extent_cell(index, "number")
    type_cell = extent_cell(index, "extent_type")
    container_summary_cell = extent_cell(index, "container_summary")
    physical_details_cell = extent_cell(index, "physical_details")
    dimensions_cell = extent_cell(index, "dimensions")
    ext_str = "Extent: #{portion_cell || "whole"} #{number_cell} #{type_cell} #{container_summary_cell} #{physical_details_cell} #{dimensions_cell}"
    errs = []
    portion = value_check(@extent_portions, (portion_cell || "whole"), errs)
    type = value_check(@extent_types, type_cell, errs)

    extent = { "portion" => portion,
               "extent_type" => type }
    extent["number"] = number_cell || nil
    extent["container_summary"] = container_summary_cell || nil
    extent["physical_details"] = physical_details_cell || nil
    extent["dimensions"] = dimensions_cell || nil
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
