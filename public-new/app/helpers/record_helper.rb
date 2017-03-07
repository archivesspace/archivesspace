module RecordHelper

  def record_for_type(result, full = false)
    klass = record_class_for_type(result.fetch('primary_type'))
    klass.new(result, full)
  end


  def record_class_for_type(type)
    case type
    when 'resource'
      Resource
    when 'archival_object'
      ArchivalObject
    when 'accession'
      Accession
    when 'digital_object'
      DigitalObject
    when 'digital_object_component'
      DigitalObjectComponent
    when 'classification'
      Classification
    when 'classification_term'
      ClassificationTerm
    when 'subject'
      Subject
    when 'top_container'
      Container
    else
      Record
    end
  end

  def record_from_resolved_json(json, full = false)
    record_for_type({
                      'json' => json,
                      'primary_type' => json.fetch('jsonmodel_type'),
                      'uri' => json.fetch('uri')
                    }, full)
  end

end
