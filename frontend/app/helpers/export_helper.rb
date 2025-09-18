require 'csv'

module ExportHelper

  def csv_response(request_uri, params = {}, filename_prefix = '')
    self.response.headers["Content-Type"] = "text/csv"
    self.response.headers["Content-Disposition"] = "attachment; filename=#{filename_prefix}#{Time.now.to_i}.csv"
    self.response.headers['Last-Modified'] = Time.now.ctime.to_s
    params["dt"] = "csv"
    self.response_body = Enumerator.new do |y|
      xml_response(request_uri, params) do |chunk, percent|
        y << chunk if !chunk.blank?
      end
    end
  end

  def xml_response(request_uri, params = {})
    JSONModel::HTTP::stream(request_uri, params) do |res|
      size, total = 0, res.header['Content-Length'].to_i
      res.read_body do |chunk|
        size += chunk.size
        percent = total > 0 ? ((size * 100) / total) : 0
        yield chunk, percent
      end
    end
  end

  # Helper method to map user-requested field names to backend field names for CSV exports
  def map_fields_for_backend(requested_fields)
    backend_fields = []
    requested_fields.each do |field|
      if field == 'context'
        # Context is special - it needs ancestor fields in the backend request
        backend_fields.concat(CSVMappingConverter.ancestor_fields)
      else
        # Map regular fields using shared method
        backend_fields << CSVMappingConverter.map_field_name(field)
      end
    end
    backend_fields
  end

  # Enhanced CSV export that handles header mapping and field transformations
  def csv_export_with_mappings(request_uri, params = {})
    # Extract requested fields from params
    requested_fields = params['fields[]'] || []

    # Map user-requested field names to backend field names for the request
    backend_fields = map_fields_for_backend(requested_fields)

    # Update params to request the correct backend field names
    params = params.dup
    params['fields[]'] = backend_fields if requested_fields.any?
    params["dt"] = "csv"

    result = nil
    JSONModel::HTTP::stream(request_uri, params) do |response|
      old_csv = CSV.parse(response.body)
      new_csv = CSVMappingConverter.new(requested_fields).build_csv_with_mappings old_csv

      # convert arrays back CSV string
      result = new_csv.map { |row| CSV.generate_line(row) }.join
    end
    result
  end

  # Handles header mapping and field transformations for CSV exports
  class CSVMappingConverter

    # Define header mappings from backend field names to user-friendly names
    # Using I18n translations with fallbacks for test environment
    def self.header_mappings
      @header_mappings ||= begin
        {
          'context' => (I18n.t('search_results.filter.top_container.context', :default => 'Resource/Accession') rescue 'Resource/Accession'),
          'container_profile_display_string_u_sstr' => (I18n.t('search_results.filter.top_container.container_profile_display_string_u_sstr', :default => 'Container Profile') rescue 'Container Profile'),
          'location_display_string_u_sstr' => (I18n.t('search_results.filter.top_container.location_display_string_u_sstr', :default => 'Location') rescue 'Location'),
          'title' => (I18n.t('search_results.filter.top_container.title', :default => 'Title') rescue 'Title'),
          'type_enum_s' => (I18n.t('search_results.filter.top_container.type', :default => 'Type') rescue 'Type'),
          'indicator_u_icusort' => (I18n.t('search_results.filter.top_container.indicator', :default => 'Indicator') rescue 'Indicator'),
          'barcode_u_sstr' => (I18n.t('search_results.filter.top_container.barcode', :default => 'Barcode') rescue 'Barcode')
        }
      end
    end

    # Map user-requested field names to actual backend field names
    FIELD_NAME_MAPPINGS = {
      'type' => 'type_enum_s',
      'indicator' => 'indicator_u_icusort',
      'barcode' => 'barcode_u_sstr'
    }.freeze

    # Cached ancestor fields for performance
    def self.ancestor_fields
      @ancestor_fields ||= ['ancestors', 'linked_instance_uris', 'linked_record_uris', 'collection_uri_u_sstr', 'digital_object']
    end

    # Shared method to map a single field name
    def self.map_field_name(field)
      FIELD_NAME_MAPPINGS[field] || field
    end

    def initialize(requested_fields = [])
      @requested_fields = requested_fields
      # Fetching JSONModel records from the backend creates a lot of overhead, and it's likely that many records have
      # the same ancestor(s), so we'll cache the titles to mitigate that.
      @title_cache = {}
    end

    # Get the actual backend field names for the requested fields
    def get_backend_field_names(requested_fields)
      requested_fields.map do |field|
        self.class.map_field_name(field)
      end
    end

    def map_header_name(header)
      self.class.header_mappings[header] || header
    end

    # Unified CSV building function with dedicated methods for headers and rows
    def build_csv_with_mappings(old_csv)
      return old_csv if old_csv.empty?

      old_headers = old_csv[0]
      # Create the header row
      new_headers = build_header_row(old_headers)
      new_csv = [new_headers]

      # Create data rows
      old_csv[1...old_csv.length].each do |old_row|
        new_row = build_data_row(old_row, old_headers)
        new_csv.append new_row
      end

      new_csv
    end

    # Method 1: Creates the header row based on requested fields
    def build_header_row(old_headers)
      headers = []

      @requested_fields.each do |requested_field|
        if requested_field == 'context'
          headers << self.class.header_mappings['context']
        else
          backend_field_name = self.class.map_field_name(requested_field)
          headers << (self.class.header_mappings[backend_field_name] || requested_field.titleize)
        end
      end

      headers
    end

    # Method 2: Creates a data row with proper field mapping and transformations
    def build_data_row(old_row, old_headers)
      row = []

      @requested_fields.each do |requested_field|
        if requested_field == 'context'
          # Build context from ancestor fields
          ancestor_field_indices = self.class.ancestor_fields.map { |field| old_headers.index(field) }.compact
          context_value = build_context_from_ancestors(old_row, old_headers, ancestor_field_indices)
          row << (context_value || '')
        else
          # Map regular fields
          backend_field_name = self.class.map_field_name(requested_field)
          field_index = old_headers.index(backend_field_name)
          value = field_index ? old_row[field_index] : nil
          row << clean_field_value(value)
        end
      end

      row
    end

    def clean_field_value(value)
      return '' if value.nil?
      return '' if value == 'null'
      return '' if value.is_a?(String) && value.strip.empty?

      # Fix force encoding and remove unnecessary escaping
      # Duplicate the string first to avoid modifying frozen strings
      cleaned_value = if value.is_a?(String)
                        value.dup.force_encoding('utf-8')
                      else
                        value.to_s.force_encoding('utf-8')
                      end

      # Remove backslash escaping of commas since CSV already handles this with quotes
      if cleaned_value.is_a?(String)
        cleaned_value = cleaned_value.gsub('\\,', ',')
        cleaned_value = cleaned_value.gsub("\\'", "'")
        cleaned_value = cleaned_value.gsub('\\"', '"')
        cleaned_value = cleaned_value.gsub('\\n', ' ')
        cleaned_value = cleaned_value.gsub('\\r', ' ')
        cleaned_value = cleaned_value.strip
      end

      cleaned_value || ''
    end

    def build_context_from_ancestors(row, headers, ancestor_indices)
      # Try to build context from ancestor fields
      ancestor_uris = []

      ancestor_indices.each do |index|
        next if index.nil?
        value = row[index]
        next if value.blank?

        if value.include?(',')
          ancestor_uris.concat(value.split(',').map(&:strip))
        else
          ancestor_uris << value.strip
        end
      end

      return nil if ancestor_uris.empty?

      # Build context string from URIs
      context_parts = []
      ancestor_uris.reverse.each do |ancestor_uri|
        next if ancestor_uri.blank?

        title = @title_cache.fetch(ancestor_uri) do |uri|
          begin
            @title_cache[uri] = JSONModel::HTTP.get_json(ancestor_uri)['title']
          rescue
            # If we can't fetch the title, use the URI as fallback
            @title_cache[uri] = uri
          end
        end
        context_parts << title
      end

      context_parts.join(' > ')
    end

  end

end
