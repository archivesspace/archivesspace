require_relative "handler"
require_relative "../../model/digital_object"

class DigitalObjectHandler < Handler
  def initialize(current_user)
    @digital_object_types ||= CvList.new("digital_object_digital_object_type", current_user)
  end

  def create(title, thumb, link, id, publish, archival_object, report)
    dig_o = nil
    dig_instance = nil
    unless !thumb && !link
      files = []
      if !link.nil? && link.start_with?("http")
        fv = JSONModel(:file_version).new._always_valid!
        fv.file_uri = link
        fv.publish = publish
        fv.xlink_actuate_attribute = "onRequest"
        fv.xlink_show_attribute = "new"
        files.push fv
      end
      if !thumb.nil? && thumb.start_with?("http")
        fv = JSONModel(:file_version).new._always_valid!
        fv.file_uri = thumb
        fv.publish = publish
        fv.xlink_actuate_attribute = "onLoad"
        fv.xlink_show_attribute = "embed"
        fv.is_representative = true
        files.push fv
      end
      osn = id.nil? ? (archival_object.ref_id + "d") : id
      dig_o = JSONModel(:digital_object).new._always_valid!
      dig_o.title = title.nil? ? archival_object.display_string : title
      dig_o.digital_object_id = osn
      dig_o.file_versions = files
      dig_o.publish = publish
      begin
        dig_o = save(dig_o, DigitalObject)
      rescue ValidationException => ve
        report.add_errors(I18n.t("bulk_import.error.dig_validation", :err => ve.errors))
        return nil
      rescue Exception => e
        raise e
      end
      report.add_info(I18n.t("bulk_import.created", :what => I18n.t("bulk_import.dig"), :id => "'#{dig_o.title}' #{dig_o.uri} [#{dig_o.digital_object_id}]"))
      dig_instance = JSONModel(:instance).new._always_valid!
      dig_instance.instance_type = "digital_object"
      dig_instance.digital_object = { "ref" => dig_o.uri }
    end
    dig_instance
  end

  def renew
    clear(@digital_object_types)
  end
end  # DigitalObjectHandler
