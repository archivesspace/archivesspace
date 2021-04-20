require 'csv'
require 'tempfile'

class ExtendedCSVExportStream

  EXCLUDED_PROPERTIES = Set.new([
    '_resolved',
    'lock_version',
    'created_by',
    'last_modified_by',
    'user_mtime',
    'system_mtime',
    'create_time',
    '_inherited',
    'tree'
  ])

  HANDLE_NESTED_RECORDS = [
    'dates',
    'extents',
    'instances',
    'sub_container',
    'digital_object',
    'subjects',
    'linked_agents',
    'names'
  ]

  # Hints for how CSV columns should be ordered.
  PARTIAL_FIELD_ORDERING = [
    'jsonmodel_type',
    'uri',
    'title',
    'display_string',
    'finding_aid_title',
    'finding_aid_',
    'id_0', 'id_1', 'id_2', 'id_3',
    'component_id',
    'ref_id',
    'level',
    'position',

    /extents::\d+::number/,
    /extents::\d+::portion/,
    /extents::\d+::type/,

    /dates::\d+::date_type/,
    /dates::\d+::label/,
    /dates::\d+::begin/,
    /dates::\d+::end/,
    /dates::\d+::expression/,
  ]

  CUSTOM_EXTRACTORS = {
    'subject::ref' => :extract_subject,
    'agent_person::ref' => :extract_agent,
    'agent_family::ref' => :extract_agent,
    'agent_corporate_entity::ref' => :extract_agent,
    'agent_software::ref' => :extract_agent,
  }

  def initialize
    @headers = Set.new
    @mapped_stream = Tempfile.new
  end

  def <<(json)
    mapped = map_record(json)

    unless mapped.empty?
      mapped.keys.each do |header|
        @headers << header
      end

      @mapped_stream.write(mapped.to_json)
      @mapped_stream.write("\n")
    end
  end

  def headers
    self.sort_headers(@headers.to_a)
  end

  def to_csv(&block)
    begin
      ordered_headers = headers

      block.call(CSV.generate_line(ordered_headers))

      @mapped_stream.rewind

      @mapped_stream.each do |line|
        r = JSON.parse(line)
        block.call(CSV.generate_line(ordered_headers.map {|h| r.fetch(h, nil)}))
      end
    ensure
      close
    end
  end

  def close
    return if @closed

    @closed = true
    @mapped_stream.close unless @mapped_stream.closed?
    @mapped_stream.unlink
  end

  protected

  def sort_headers(headers)
    # First pass: order headers alphabetically, which groups columns into their subrecords
    headers.sort!

    # Sort according to our PARTIAL_FIELD_ORDERING above, keeping subrecords
    # together but ordering within them as needed.
    headers.sort_by! {|h|
      fields = h.split('::')

      path = fields[0...-1].map {|f| (f =~ /\A[0-9]+\z/) ? sprintf('%05d', f) : f}.join('::')
      field = fields[-1]

      score = PARTIAL_FIELD_ORDERING.index(h) ||
              PARTIAL_FIELD_ORDERING.index {|elt| elt.is_a?(Regexp) && h =~ elt} ||
              999

      "#{path}::#{sprintf('%05d', score)}::#{field}"
    }

    headers
  end

  def extract_properties(r)
    result = extract_properties_with_custom_extractor(r)

    result || extract_scalar_properties(r)
  end

  def extract_properties_with_custom_extractor(r)
    extractor_description = nil

    if r.is_a?(Hash)
      extractor_description = r['jsonmodel_type']

      extractor_description ||= if r['_resolved'] && r['_resolved']['jsonmodel_type']
                                  "%s::ref" % [r['_resolved']['jsonmodel_type']]
                                end
    end

    if extractor = extract_properties_for_type(extractor_description)
      self.send(extractor, r)
    else
      nil
    end
  end

  def extract_properties_for_type(jsonmodel_type)
    CUSTOM_EXTRACTORS.fetch(jsonmodel_type, nil)
  end

  def extract_subject(r)
    if r.include?('_resolved')
      r = r.fetch('_resolved')
    end

    extract_scalar_properties(r).select {|k, _| ['source', 'title', 'uri'].include?(k)}
  end

  def extract_agent(r)
    if r.include?('_resolved')
      r = r.fetch('_resolved')
    end

    extract_scalar_properties(r)
  end

  def exclude_property?(prop)
    @extra_excluded_properties ||= Set.new(AppConfig[:extended_csv_export_extra_excluded_properties])

    EXCLUDED_PROPERTIES.include?(prop) || @extra_excluded_properties.include?(prop)
  end

  def nested_records
    @nested_records ||= (HANDLE_NESTED_RECORDS + AppConfig[:extended_csv_export_extra_nested_records])
  end

  def extract_scalar_properties(r)
    result = r.select {|k, v| !exclude_property?(k) && (v.is_a?(String) || v.is_a?(Integer) || v.is_a?(Float))}

    # Treat refs specially here, flattening them out.
    r.each do |k, v|
      if !exclude_property?(k) && v.is_a?(Hash) && v['ref']
        (extract_properties_with_custom_extractor(v) || v).each do |ref_key, ref_val|
          next if exclude_property?(ref_key)
          result["#{k}::#{ref_key}"] = ref_val
        end
      end
    end

    result
  end

  def max_nested
    @max_nested ||= AppConfig[:extended_csv_export_max_nested_records]
  end

  def map_record(r)
    return r unless r.is_a?(Hash)

    mapped = extract_properties(r)

    self.nested_records.each do |property|
      ASUtils.wrap(r.fetch(property, [])).each_with_index do |nested, idx|
        next unless nested.is_a?(Hash)
        next if idx > max_nested

        mapped_nested = map_record(nested)

        mapped_nested.each do |k, v|
          if idx == max_nested
            v = "MAX_NESTED_RECORDS_REACHED"
          end

          mapped["#{property}::#{idx}::#{k}"] = v
        end
      end
    end

    mapped
  end

end
