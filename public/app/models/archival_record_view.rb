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


  def published_instances
    instances = []

    @record['instances'].each do |instance|
      if instance['instance_type'] === "digital_object"
        if instance['digital_object'] && instance['digital_object']['_resolved']['publish']
          instances.push(instance)
        end
      else
        instances.push(instance)
      end
    end

    instances
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


  def published_notes
    notes = Array(@record['notes']).find_all {|doc| doc['publish'] === true}

    notes.each do |note|
      if note.has_key?('subnotes')
        note['subnotes'] = Array(note['subnotes']).find_all {|doc| doc['publish'] === true}
      end
    end

    notes
  end


  def method_missing(method, *args, &block)
    @record.send(method, *args, &block)
  end
end
