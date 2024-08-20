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

  # This is meant to be used by the search controller to be able to fill in the derived "context" column,
  # since JSONModel can't do that as it isn't stored/indexed.
  def csv_export_with_context(request_uri, params = {})
    params["dt"] = "csv"
    JSONModel::HTTP::stream(request_uri, params) do |response|
      old_csv = CSV.parse(response.body)
      new_csv = ContextConverter.new.convert_ancestors_to_context old_csv

      # convert arrays back CSV string
      return new_csv.map(&:to_csv).join
    end
  end

  # Creates a "context" string intended to match what is displayed in the Staff UI for search results.
  class ContextConverter

    # There are several different fields that 'context' data may potentially be drawn from
    def self.ancestor_fields
      ['ancestors', 'linked_instance_uris', 'linked_record_uris', 'collection_uri_u_sstr', 'digital_object']
    end

    def initialize
      # Fetching JSONModel records from the backend creates a lot of overhead, and it's likely that many records have
      # the same ancestor(s), so we'll cache the titles to mitigate that.
      @title_cache = {}
    end

    def convert_ancestors_to_context(old_csv)
      # we want all the columns from the search except for the various ancestor fields, which will all end up in context
      new_csv = [old_csv[0].reject {|header| self.class.ancestor_fields.include? header}]
      new_csv[0].append 'context'
      new_row_length = new_csv[0].length
      context_column_index = new_csv[0].index 'context'

      column_map = []
      old_csv[0].each_with_index do |old_column, old_column_index|
        new_column_index = new_csv[0].index(old_column)
        if new_column_index
          column_map[old_column_index] = new_column_index
        else
          column_map[old_column_index] = context_column_index
        end
      end

      old_csv[1...old_csv.length].each do |old_row|
        new_row = Array.new(new_row_length)
        column_map.each_with_index do |new_column_index, old_column_index|
          if new_column_index == context_column_index
            # these ones need to be moved to the context column if they exist
            uris = old_row[old_column_index]
            new_row[new_column_index] = context_string(uris.split ',') unless uris.blank?
          else
            new_row[new_column_index] = old_row[old_column_index]
          end
        end
        new_csv.append new_row
      end

      new_csv
    end

    private

    # given a list of ancestor URIs, look up record titles and construct context string that matches the frontend display
    def context_string(ancestor_uris)
      ancestor_context = ''
      ancestor_uris.reverse.each_with_index do |ancestor_uri, i|
        title = @title_cache.fetch(ancestor_uri) do |uri|
          @title_cache[uri] = JSONModel::HTTP.get_json(ancestor_uri)['title']
        end
        ancestor_context += title
        ancestor_context += ' > ' if i < ancestor_uris.length - 1
      end
      ancestor_context
    end

  end

end
