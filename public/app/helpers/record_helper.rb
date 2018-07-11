module RecordHelper

  def record_for_type(result, full = false)
    klass = record_class_for_type(result.fetch('primary_type'))
    klass.new(result, full)
  end


  def record_class_for_type(type)

    case type
    when 'resource'
      Resource
    when 'resource_ordered_records'
      ResourceOrderedRecords
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
    when 'agent_person'
      AgentPerson
    when 'agent_family'
      AgentFamily
    when 'agent_corporate_entity'
      AgentCorporateEntity
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

  def icon_for_type(primary_type)
    'fa ' + case primary_type
              when 'repository'
              'fa-home'
              when  'resource'
              'fa-archive'
              when 'archival_object'
              'fa-file-o'
              when 'digital_object'
              'fa-file-image-o'
              when 'accession'
              'fa-file-text-o'
              when 'subject'
              'fa-tag'
              when  'agent_person'
              'fa-user'
              when 'agent_corporate_entity'
              'fa-university'
              when 'agent_family'
              'fa-users'
              when 'classification'
              'fa-share-alt'
              when 'top_container'
              'fa-archive'
              else
              'fa-cog'
            end
  end

  def badge_for_type(primary_type)
    "<span class='record-type-badge #{primary_type}' aria-hidden='true'> \
      <i class='#{icon_for_type(primary_type)}'></i> \
    </span>".html_safe
  end

end
