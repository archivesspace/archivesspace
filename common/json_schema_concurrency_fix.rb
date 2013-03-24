# Monkey patch against json-schema 1.0.12 to work around
# https://github.com/hoxworth/json-schema/issues/24


module JSON
  class Validator

    # Run a simple true/false validation of data against a schema
    def validate()
      begin
        Validator.clear_errors
        @base_schema.validate(@data,[],@validation_options)
        Validator.clear_cache
        if @options[:errors_as_objects]
          self.class.validation_errors.map{|e| e.to_hash}
        else
          self.class.validation_errors.map{|e| e.to_string}
        end
      rescue JSON::Schema::ValidationError
        Validator.clear_cache
        raise $!
      end
    end

    class << self
      def clear_errors
        Thread.current[:jsonschema_errors] = []
      end

      def validation_error(error)
        Thread.current[:jsonschema_errors] << error
      end

      def validation_errors
        Thread.current[:jsonschema_errors] or []
      end
    end


    # Plus one bonus: don't use MultiJson here.
    def serialize schema
      # if defined?(MultiJson)
      #   MultiJson.respond_to?(:dump) ? MultiJson.dump(schema) : MultiJson.encode(schema)
      # else
      #   @@serializer.call(schema)
      # end

      ASUtils.to_json(schema)
    end

  end
end
