class ValidatorCache

  def self.create_validator(jsonmodel, data)
    JSON::Validator.new(jsonmodel.schema,
                        data,
                        :errors_as_objects => true,
                        :record_errors => true)
  end

  def self.with_validator_for(jsonmodel, data)
    Thread.current[:validator_cache] ||= {}

    created = false
    if Thread.current[:validator_cache][jsonmodel]

      # If we have a cache entry but it's in use, just return a newly allocated
      # validator.
      if Thread.current[:validator_cache][jsonmodel][:in_use]
        return self.create_validator(jsonmodel, data)
      end

    else
      # If there's no entry, add one
      Thread.current[:validator_cache][jsonmodel] = {}
      Thread.current[:validator_cache][jsonmodel][:validator] = self.create_validator(jsonmodel, data)
      created = true
    end

    validator = Thread.current[:validator_cache][jsonmodel][:validator]

    # Reuse this existing validator by setting its data
    if !created
      validator.instance_eval do
        @data = data
      end
    end

    Thread.current[:validator_cache][jsonmodel][:in_use] = true

    begin
      yield(validator)
    ensure
      Thread.current[:validator_cache][jsonmodel][:in_use] = false
    end
  end

end
