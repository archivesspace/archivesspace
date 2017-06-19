class ArchivalObject < Record
  include TreeNodes
  include ResourceRequestItems

  def parse_notes
    rewrite_refs(json['notes'], resource_uri) if resource_uri

    super
  end

  def resource_uri
    resolved_resource && resolved_resource['uri']
  end

  def direct_component_id
    if json.has_key?('component_id_inherited')
      ''
    else
      json.fetch('component_id', '')
    end
  end

  def instances
    json['instances']
  end

  def finding_aid
    # as this shares the same template as resources,
    # be clear that this object doesn't have a finding aid
    nil
  end

  def cite
    cite = note('prefercite')
    unless cite.blank?
      cite = strip_mixed_content(cite['note_text'])
    else
      cite = strip_mixed_content(display_string) + "."

      if resolved_resource
        ttl = resolved_resource.dig('title')

        cite += " #{strip_mixed_content(ttl)}"
        cite += "," unless cite.end_with?(',')
        cite += " #{identifier}"

        cite += "."
      end

      cite += " #{ repository_information['top']['name']}." unless !repository_information.dig('top','name')
    end

    "#{cite}   #{cite_url_and_timestamp}."
  end

  def root_node_uri
    json.fetch('resource').fetch('ref')
  end

end
