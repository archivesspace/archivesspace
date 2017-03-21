class DigitalObject < Record

  attr_reader :cite

  def initialize(*args)
    super

    #@linked_records = parse_digital_archival_info
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

  def parse_digital_archival_info
    results = {}

    unless json['linked_instances'].empty? || !json['linked_instances'][0].dig('ref')
      uri = json['linked_instances'][0].dig('ref')
      uri << '#pui' unless uri.end_with?('#pui')

      begin
        arch = archives_space_client.get_record(uri, @search_opts)
        results[uri] = arch
        # GONE # @tree = fetch_tree(uri.sub('#pui','')) if @tree['path_to_root'].blank?
      rescue RecordNotFound
        # Assume not published or not yet indexed
      end
    end
    
    results
  end

  private

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
end
