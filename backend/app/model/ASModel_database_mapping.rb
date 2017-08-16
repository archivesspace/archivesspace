module ASModel
  # Some low-level details of mapping certain Ruby types to database types.
  module DatabaseMapping

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      JSON_TO_DB_MAPPINGS = {
        'boolean' => {
          :description => "JSON booleans become DB integers",
          :json_to_db => ->(bool) { bool ? 1 : 0 },
          :db_to_json => ->(int) { int === 1 }
        },
        'date' => {
          :description => "Date strings become dates",
          :json_to_db => ->(s) { s.nil? ? s : Date.parse(s) },
          :db_to_json => ->(date) { date.nil? ? date : date.strftime('%Y-%m-%d') }
        }
      }


      def prepare_for_db(jsonmodel_class, hash)
        schema = jsonmodel_class.schema
        hash = hash.clone
        schema['properties'].each do |property, definition|
          mapping = JSON_TO_DB_MAPPINGS[definition['type']]
          if mapping && hash.has_key?(property)
            hash[property] = mapping[:json_to_db].call(hash[property])
          end
        end

        nested_records.each do |nested_record|
          # Nested records will be processed separately.
          hash.delete(nested_record[:json_property].to_s)
        end

        hash['json_schema_version'] = jsonmodel_class.schema_version

        hash
      end


      def map_db_types_to_json(schema, hash)
        hash = hash.clone
        schema['properties'].each do |property, definition|
          mapping = JSON_TO_DB_MAPPINGS[definition['type']]

          property = property.intern
          if mapping && hash.has_key?(property)
            hash[property] = mapping[:db_to_json].call(hash[property])
          end
        end

        hash
      end
    end
  end
end
