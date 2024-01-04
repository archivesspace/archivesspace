require 'securerandom'
require_relative "handler"
require_relative "../../model/digital_object"

class DigitalObjectHandler < Handler
  def initialize(current_user, validate_only = false)
    super
    # we don't currently use this, but it will come in handy with enhancements
    @digital_object_types ||= CvList.new("digital_object_digital_object_type", @current_user)
  end

  def check_digital_id(dig_id)
    params = { :q => "digital_object_id:\"#{dig_id}\"" }
    ret = search(nil, params, :digital_object, "digital_object", "", @report)
    ret = ret.nil?
  end

  def create(title, id, publish, archival_object, report,
             representative_file_version = nil, non_representative_file_version = nil)
    dig_o = nil
    dig_instance = nil

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
=begin
      if @validate_only
        I18n.t("bulk_import.error.dig_obj_unique", :id => osn)
        report.add_errors(I18n.t("bulk_import.error.dig_obj_unique", :id => osn))
      else
=end
      raise BulkImportException.new(I18n.t("bulk_import.error.dig_obj_unique", :id => osn))
      #      end
    end

    files = []
    files.push JSONModel(:file_version).from_hash(representative_file_version) if representative_file_version
    files.push JSONModel(:file_version).from_hash(non_representative_file_version) if non_representative_file_version

    dig_o = JSONModel(:digital_object).new._always_valid!
    dig_o.title = title.nil? ? archival_object.display_string : title
    dig_o.digital_object_id = osn
    dig_o.file_versions = files if files.any?
    dig_o.publish = publish
    begin
      dig_o = save(dig_o, DigitalObject)
    rescue JSONModel::ValidationException => ve
      report.add_errors(I18n.t("bulk_import.error.dig_validation", :err => ve.errors))
      return nil
    rescue Exception => e
      raise e
    end
    report.add_info(I18n.t(@create_key, :what => I18n.t("bulk_import.dig"), :id => "'#{dig_o.title}' #{dig_o.uri} [#{dig_o.digital_object_id}]"))
    dig_instance = JSONModel(:instance).new._always_valid!
    dig_instance.instance_type = "digital_object"
    dig_instance.digital_object = { "ref" => @validate_only ? "http://x" : dig_o.uri }
    dig_instance
  end

  def renew
    clear(@digital_object_types)
  end
end  # DigitalObjectHandler
