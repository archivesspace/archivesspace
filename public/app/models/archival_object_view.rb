# Restrict an JSONModel(:archival_object) to a subset
class ArchivalObjectView

  def initialize(archival_object)
    @archival_object = archival_object
  end


  def digital_objects
    digital_objects = {}

    if not @archival_object['instances'].blank?
      @archival_object['instances'].each do |instance|
        if instance['instance_type'] === "digital_object"
          digital_objects[instance['digital_object']['ref']] = instance['digital_object']['_resolved']
        end
      end
    end

    digital_objects
  end


  def published_external_documents
    Array(@archival_object['external_documents']).find_all {|doc| doc['publish'] === true}
  end


  def published_agents
    Array(@archival_object['linked_agents']).find_all {|doc| doc['_resolved']['publish'] === true}
  end


  def method_missing(method, *args, &block)
    @archival_object.send(method, *args, &block)
  end
end
