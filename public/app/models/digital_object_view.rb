# Restrict an JSONModel(:digital_object) to a subset
class DigitalObjectView < ArchivalRecordView

  def published_file_versions
    Array(@record['file_versions']).find_all {|doc| doc['publish'] === true}
  end

  def published_linked_instances
    Array(@record['linked_instances']).find_all {|doc| doc['_resolved']['publish'] === true}
  end

end
