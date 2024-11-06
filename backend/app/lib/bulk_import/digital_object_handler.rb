require 'securerandom'
require_relative "handler"
require_relative "../../model/digital_object"

class DigitalObjectHandler < Handler
  def initialize(current_user, validate_only = false)
    super
    # we don't currently use this, but it will come in handy with enhancements
    @digital_object_types ||= CvList.new("digital_object_digital_object_type", @current_user)
    @file_format_names    ||= CvList.new("file_version_file_format_name", @current_user)
    @file_use_statement   ||= CvList.new("file_version_use_statement", @current_user)
  end

  def check_digital_id(dig_id)
    params = { :q => "digital_object_id:\"#{dig_id}\"" }
    ret = search(nil, params, :digital_object, "digital_object", "", @report)
    ret = ret.nil?
  end

  def create(
      title,
      id,
      publish,
      level,
      digital_object_type,
      restrictions,
      dates,
      notes,
      extents,
      subjects,
      linked_agents,
      archival_object,
      report,
      representative_file_version = nil,
      non_representative_file_version = nil
    )
    digital_object = nil
    digital_object_instance = nil

    # might as well check the dig_id first
    if @validate_only
      if archival_object.nil?
        archival_object = JSONModel(:archival_object).new._always_valid!
        archival_object.title = "random title"
        archival_object.ref_id = "VAL#{rand(1000000)}"
      end
    end
    osn = id || SecureRandom.hex
    if !check_digital_id(osn)
      raise BulkImportException.new(I18n.t("bulk_import.error.dig_obj_unique", :id => osn))
    end

    errors = []
    if representative_file_version
      errors << validate_enum(representative_file_version[:file_format_name], @file_format_names, report)
      errors << validate_enum(representative_file_version[:use_statement], @file_use_statement, report)
    end

    if non_representative_file_version
      errors << validate_enum(non_representative_file_version[:file_format_name], @file_format_names, report)
      errors << validate_enum(non_representative_file_version[:use_statement], @file_use_statement, report)
    end

    return nil unless errors.compact.empty?

    files = []
    files.push JSONModel(:file_version).from_hash(representative_file_version) if representative_file_version
    files.push JSONModel(:file_version).from_hash(non_representative_file_version) if non_representative_file_version

    digital_object = JSONModel(:digital_object).new._always_valid!
    digital_object.title = title.nil? ? archival_object.display_string : title
    digital_object.digital_object_id = osn
    digital_object.file_versions = files if files.any?
    digital_object.publish = publish
    digital_object.level = level
    digital_object.digital_object_type = digital_object_type
    digital_object.restrictions = restrictions
    digital_object.dates = dates
    digital_object.notes = notes
    digital_object.extents = extents
    subjects.each { |subject| digital_object.subjects.push({ "ref" => subject.uri }) }

    digital_object.linked_agents = linked_agents

    begin
      digital_object = save(digital_object, DigitalObject)
    rescue JSONModel::ValidationException => ve
      report.add_errors(I18n.t("bulk_import.error.dig_validation", :err => ve.errors))
      return nil
    rescue Exception => e
      raise e
    end
    report.add_info(I18n.t(@create_key, :what => I18n.t("bulk_import.dig"), :id => "'#{digital_object.title}' #{digital_object.uri} [#{digital_object.digital_object_id}]"))
    digital_object_instance = JSONModel(:instance).new._always_valid!
    digital_object_instance.instance_type = "digital_object"
    digital_object_instance.digital_object = { "ref" => @validate_only ? "http://x" : digital_object.uri }
    digital_object_instance
  end

  def renew
    clear(@digital_object_types)
  end


  private

  def validate_enum(value, enum_values, report)
    return if value.nil? || value.empty?

    errs = []
    return if value_check(enum_values, value, errs)

    error = I18n.t("bulk_import.error.dig_validation", :err => errs[0])
    report.add_errors(error)
    return error
  end
end
