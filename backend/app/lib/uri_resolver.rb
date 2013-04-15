module URIResolver

  include JSONModel

  def self.resolve_references(value, properties_to_resolve, env)
    value = value.to_hash(:trusted) if value.is_a?(JSONModelType)

    # If ASPACE_REENTRANT is set, don't resolve anything or we risk creating loops.
    return value if (properties_to_resolve.nil? || env['ASPACE_REENTRANT'])

    if value.is_a? Hash
      if value.has_key?('ref') && properties_to_resolve == :all
        _resolve_reference(value, env)
      else
        result = value.clone

        value.each do |k, v|
          if properties_to_resolve.is_a?(Array) && properties_to_resolve.include?(k)
            result[k] = (v.is_a? Array) ? v.map {|elt| _resolve_reference(elt, env)} : _resolve_reference(v, env)
          else
            result[k] = resolve_references(v, properties_to_resolve, env)
          end
        end

        result
      end


    elsif value.is_a? Array
      value.map {|elt| resolve_references(elt, properties_to_resolve, env)}
    else
      value
    end
  end


  def resolve_references(value, properties_to_resolve)
    URIResolver.resolve_references(value, properties_to_resolve, env)
  end


  # Redispatch the current request to a different route handler.
  #
  # Careful: If env is nil this bypasses the usual permission checking when fetching records.
  #
  # Usually we'll want to resolve records with the permissions of the user
  # making the request, so pass through the env from their request.
  #
  def self.resolve_uri(uri, env)
    if env
      env = env.merge('ASPACE_REENTRANT' => true, 'PATH_INFO' => uri)
    else
      env = {
        'REQUEST_METHOD' => "GET",
        'SCRIPT_NAME' => "",
        'PATH_INFO' => uri,
        'QUERY_STRING' => "",
        'SERVER_NAME' => "archivesspace.org",
        'SERVER_PORT' => 80,
        'rack.input' => StringIO.new,
        'ASPACE_REENTRANT' => true
      }
    end

    response = ArchivesSpaceService.call(env)

    resolved = ""

    response[2].each do |s|
      resolved += s
    end

    resolved
  end


  private


  def self._resolve_reference(reference, env)
    if !reference.is_a? Hash
      raise "Argument must be a {'ref' => '/uri'} hash (not: #{reference})"
    end

    if JSONModel.parse_reference(reference['ref'])
      record = resolve_uri(reference['ref'], env)
      reference.clone.merge('_resolved' => ASUtils.json_parse(record))
    else
      raise "Couldn't parse ref: #{reference.inspect}"
    end
  end



end
