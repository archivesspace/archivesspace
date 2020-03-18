class DigitalObject < Record

  attr_reader :cite, :cite_item, :cite_item_description, :linked_instances
  def initialize(*args)
    super

    @linked_instances = parse_linked_instances
    @cite = parse_cite_string
    @cite_item = parse_cite_item_string
    @cite_item_description = parse_cite_item_description_string
  end

  def finding_aid
    # as this shares the same template as resources,
    # be clear that this object doesn't have a finding aid
    nil
  end

  def root_node_uri
    uri
  end

  def breadcrumb
    [
      {
        :uri => '',
        :type => 'digital_object',
        :crumb => display_string
      }
    ]
  end

  private

  def parse_identifier
    json['digital_object_id']
  end

  def parse_linked_instances
    results = {}

    unless ASUtils.wrap(json['linked_instances']).empty?
      for instance in json['linked_instances']
        uri = instance.dig('ref')
        record = linked_instance_for_uri(uri)
        next if record.nil?

        results[uri] = record_for_type(record)
      end
    end
    
    results
  end

  def parse_cite_string
    cite = note('prefercite')
    unless cite.blank?
      cite = strip_mixed_content(cite['note_text'])
    else
      cite = strip_mixed_content(display_string) + "."
      if resolved_resource
        ttl = resolved_resource.dig('title')
        cite += " #{strip_mixed_content(ttl)}." unless !ttl
      end
      cite += " #{ repository_information['top']['name']}." unless !repository_information.dig('top','name')
    end

    HTMLEntities.new.decode("#{cite}   #{cite_url_and_timestamp}.")
  end

  def parse_cite_item_string
    cite = note('prefercite')
    unless cite.blank?
      cite = strip_mixed_content(cite['note_text'])
    else
      cite = strip_mixed_content(display_string)
      cite += identifier.blank? ? '' : ", #{identifier}"
      cite += if container_display.blank? || container_display.length > 5
        '.'
      else
        @citation_container_display ||= parse_container_display(:citation => true).join('; ')
        ", #{@citation_container_display}."
      end
      unless repository_information['top']['name'].blank?
        cite += " #{ repository_information['top']['name']}."
      end
    end
    HTMLEntities.new.decode("#{cite}")
  end

  def parse_cite_item_description_string
    cite = note('prefercite')
    unless cite.blank?
      cite = strip_mixed_content(cite['note_text'])
    else
      cite = strip_mixed_content(display_string)
      cite += identifier.blank? ? '' : ", #{identifier}"
      cite += if container_display.blank? || container_display.length > 5
        '.'
      else
        @citation_container_display ||= parse_container_display(:citation => true).join('; ')
        ", #{@citation_container_display}."
      end
      unless repository_information['top']['name'].blank?
        cite += " #{ repository_information['top']['name']}."
      end
    end
    HTMLEntities.new.decode("#{cite}   #{cite_url_and_timestamp}.")
  end

  def linked_instance_for_uri(uri)
    if raw['_resolved_linked_instance_uris']
      resolved = raw['_resolved_linked_instance_uris'].fetch(uri, nil)

      if resolved
        resolved.first
      end
    end
  end

  def build_request_item
    request = RequestItem.new({})

    request[:request_uri] = uri
    request[:repo_name] = resolved_repository.dig('name')
    request[:repo_code] = resolved_repository.dig('repo_code')
    request[:repo_uri] = resolved_repository.dig('uri')
    request[:repo_email] = resolved_repository.dig('agent_representation', '_resolved', 'agent_contacts', 0, 'email')
    request[:cite] = cite
    request[:identifier] = identifier
    request[:title] = display_string
    request[:linked_record_uris] = @linked_instances.keys

    note = note('accessrestrict')
    unless note.blank?
      request[:restrict] = note['note_text']
    end

    request[:hierarchy] = breadcrumb.reverse.drop(1).reverse.collect{|record| record[:crumb]}

    request
  end
end
