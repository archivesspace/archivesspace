require_relative "mixins/record_children"

class DigitalRecordChildren < JSONModel(:digital_record_children)

  include RecordChildren

  attr_accessor :uri

  def self.uri_for(*args)
    nil
  end

  def self.clean(child)
    super
    clean_file_versions(child)
  end

  def self.clean_file_versions(child)
    return unless child["file_versions"]

    if child["file_versions"][0].reject{|k,v| (k == "publish" && v == true) || v.blank?}.empty?
      child.delete("file_versions")
    end
  end

end
