require_relative "mixins/record_children"

class ArchivalRecordChildren < JSONModel(:archival_record_children)

  include RecordChildren


  attr_accessor :uri

  def self.uri_for(*args)
    nil
  end


  def self.clean(child)
    super
    clean_instances(child)
  end


  def self.clean_instances(child)
    return if !child["instances"] || child["instances"].empty?

    child["instances"] = [child["instances"].first]

    if child["instances"][0]["sub_container"].reject{|k,v| v.blank?}.empty?
      child["instances"][0].delete("sub_container")
    end

    if !child["instances"][0].has_key?("sub_container") && child["instances"][0]["instance_type"].blank?
      child["instances"] = []
    end
  end

end
