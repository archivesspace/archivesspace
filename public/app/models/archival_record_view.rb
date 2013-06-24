# Restrict an JSONModel(:digital_object) to a subset
class ArchivalRecordView

  def initialize(record)
    @record = record
  end


  # Make our wrapping methods show up when accessed as a hash too
  def [](k)
    result = @record[k]

    if !result
      m = "#{k}".intern
      result = if self.respond_to?(m)
                 self.send(m)
               end
    end

    result
  end


  def digital_objects
    digital_objects = {}

    if not @record['instances'].blank?
      @record['instances'].each do |instance|
        if instance['instance_type'] === "digital_object"
          digital_objects[instance['digital_object']['ref']] = instance['digital_object']['_resolved']
        end
      end
    end

    digital_objects
  end


  def published_external_documents
    Array(@record['external_documents']).find_all {|doc| doc['publish'] === true}
  end


  def published_agents
    Array(@record['linked_agents']).find_all {|doc| doc['_resolved']['publish'] === true}
  end


  def published_file_versions
    Array(@record['file_versions']).find_all {|doc| doc['publish'] === true}
  end


  def method_missing(method, *args, &block)
    @record.send(method, *args, &block)
  end
end
