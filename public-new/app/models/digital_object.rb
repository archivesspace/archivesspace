class DigitalObject < Record

  attr_reader :cite, :linked_instances
  def initialize(*args)
    super

    @linked_instances = parse_linked_instances
    @cite = parse_cite_string
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
        :crumb => display_string
      }
    ]
  end

  private

  def parse_linked_instances
    results = {}

    unless ASUtils.wrap(json['linked_instances']).empty?
      for instance in json['linked_instances']
        uri = instance.dig('ref')
        record = linked_instance_for_uri(uri)
        next if record.nil?

        results[uri] = record_from_resolved_json(record)
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

    "#{cite}   #{cite_url_and_timestamp}."
  end

  def linked_instance_for_uri(uri)
    if raw['_resolved_linked_instance_uris']
      resolved = raw['_resolved_linked_instance_uris'].fetch(uri, nil)

      if resolved
        resolved.first
      end
    end
  end
end
