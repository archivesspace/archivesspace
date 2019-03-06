require 'csv'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/schemas')
    .description("Get all ArchivesSpace schemas")
    .params()
    .permissions([])
    .returns([200, "ArchivesSpace (schemas)"]) \
  do
    schemas = Hash[ models.keys.map { |schema| [schema, JSONModel(schema.to_sym).schema] } ]
    json_response( schemas )
  end

  def strip_jsonmodel(s)
    if s.is_a?(String)
      if s =~ /JSONModel\(:(.*?)\) (.*)/
        return "#{$1} #{$2}"
      end
    end

    s
  end


  def schema_format_type(property_def)
    if property_def.is_a?(String)
      return strip_jsonmodel(property_def)
    end

    if property_def['type'].is_a?(String) && property_def['type'] == 'array'
      "ARRAY[%s]" % [schema_format_type(property_def['items'])]
    elsif property_def['type'] == 'object'
      if property_def['subtype'] == 'ref'
        schema_format_type(property_def['properties']['ref'])
      else
        strip_jsonmodel(property_def['type'])
      end
    elsif property_def['type'].is_a?(Array)
      property_def['type'].map {|elt| schema_format_type(elt)}.join(' OR ')
    else
      strip_jsonmodel(property_def['type'])
    end

  end

  Endpoint.get('/schemas.csv')
    .description("Get all ArchivesSpace schemas in CSV format")
    .params()
    .permissions([])
    .returns([200, "ArchivesSpace (schemas)"]) \
  do

    skipped_fields = ['uri', 'lock_version', 'jsonmodel_type', 'created_by', 'last_modified_by', 'user_mtime', 'system_mtime', 'create_time', 'history']

    csv = CSV.generate do |csv|
      csv << ["Record type", "Field name", "Field type", "What happens when missing?"]

      JSONModel.models.each do |jsonmodel_name, jsonmodel|
        next if jsonmodel_name.start_with?('abstract_')
        jsonmodel.schema['properties'].each do |property, property_def|
          next if property_def['readonly'].to_s == 'true'

          next if skipped_fields.include?(property)
          row = [
            jsonmodel_name.to_s,
            property,
            schema_format_type(property_def),
            property_def['readonly'].to_s == 'true' ? '-' : property_def.fetch('ifmissing', 'ignore'),
          ]

          csv << row
        end
      end
    end

    [200, {'Content-Type' => 'text/plain'}, csv]
  end


  Endpoint.get('/schemas/:schema')
    .description("Get an ArchivesSpace schema")
    .params(["schema", String, "Schema name to retrieve"])
    .permissions([])
    .returns([200, "ArchivesSpace (:schema)"],
             [404, "Schema not found"]) \
  do
    schema = params[:schema]
    if models.has_key? schema
      json_response( JSONModel(schema.to_sym).schema )
    else
      raise NotFoundException.new
    end
  end

end
