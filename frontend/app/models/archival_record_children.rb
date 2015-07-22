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
    return unless child["instances"]

    if child["instances"][0]["container"].reject{|k,v| v.blank?}.empty?
      child["instances"][0].delete("container")
    end
    if !child["instances"][0].has_key?("container") and child["instances"][0]["instance_type"].blank?
      child.delete("instances")
    end
  end

end
