# Restrict an JSONModel(:digital_object) to a subset
class DigitalObjectView

  def initialize(archival_object)
    @digital_object = archival_object
  end


  def published_external_documents
    Array(@digital_object['external_documents']).find_all {|doc| doc['publish'] === true}
  end


  def published_agents
    Array(@digital_object['linked_agents']).find_all {|doc| doc['_resolved']['publish'] === true}
  end


  def published_file_versions
    Array(@digital_object['file_versions']).find_all {|doc| doc['publish'] === true}
  end


  def method_missing(method, *args, &block)
    @digital_object.send(method, *args, &block)
  end
end
