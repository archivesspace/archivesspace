class DigitalObject < Record

  def initialize(*args)
    super

    #@linked_records = parse_digital_archival_info
  end

  def finding_aid
    # as this shares the same template as resources,
    # be clear that this object doesn't have a finding aid
    nil
  end

  private

  def parse_digital_archival_info
    results = {}

    unless json['linked_instances'].empty? || !json['linked_instances'][0].dig('ref')
      uri = json['linked_instances'][0].dig('ref')
      uri << '#pui' unless uri.end_with?('#pui')

      begin
        arch = archives_space_service.get_record(uri, @search_opts)
        results[uri] = arch
        @tree = fetch_tree(uri.sub('#pui','')) if @tree['path_to_root'].blank?
      rescue RecordNotFound
        # Assume not published or not yet indexed
      end
    end
    
    results
  end
end