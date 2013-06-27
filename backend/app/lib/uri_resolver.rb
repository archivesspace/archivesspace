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


  def self.ensure_reference_is_valid(reference, active_repository = nil)

    # error on anything that points outside the active repository
    if active_repository && \
      reference.start_with?("/repositories/") && \
      reference !~ /^\/repositories\/#{active_repository}($|\/)/

      raise ReferenceError.new("Inter-repository links are not allowed in this operation! (Bad link: '#{reference}'; Active repo: '#/repositories/#{active_repository}')")
    end

    # ensure the referent record actually exists
    if !self.record_exists?(reference)
      raise ReferenceError.new("Reference does not exist! (Reference: '#{reference}')")
    end
  end


  def resolve_references(value, properties_to_resolve)
    URIResolver.resolve_references(value, properties_to_resolve, env)
  end


  def self.record_exists?(uri)
    parsed = JSONModel.parse_reference(uri)

    if parsed
      begin
        model = Kernel.const_get(parsed[:type].camelize)
        return !model[parsed[:id]].nil?
      rescue NameError
        # Questionable, but deal with URIs like /repositories/2/resources/1/tree
        # yielding "ResourceTree" which isn't a real model.
        return true
      end
    end

    false
  end


  # Redispatch the current request to a different route handler.
  #
  # Careful: If env is nil this bypasses the usual permission checking when fetching records.
  #
  # Usually we'll want to resolve records with the permissions of the user
  # making the request, so pass through the env from their request.
  #
  def self.forward_rack_request(method, uri, env)
    if env
      env = env.merge('ASPACE_REENTRANT' => true, 'PATH_INFO' => uri,
                      'REQUEST_METHOD' => method)
    else
      env = {
        'REQUEST_METHOD' => method,
        'SCRIPT_NAME' => "",
        'PATH_INFO' => uri,
        'QUERY_STRING' => "",
        'SERVER_NAME' => "archivesspace.org",
        'SERVER_PORT' => 80,
        'rack.input' => StringIO.new,
        'ASPACE_REENTRANT' => true
      }
    end

    ArchivesSpaceService.call(env)
  end


  def self.resolve_uri(uri, env)
    ASModel.all_models.each {|model|
      jsonmodel = model.my_jsonmodel(true)
      next if !jsonmodel

      id = jsonmodel.id_for(uri, {}, true)
      if id
        return model.to_jsonmodel(id).to_json(:mode => :trusted)
      end
    }

    response = forward_rack_request("GET", uri, env)

    resolved = ""

    response[2].each do |s|
      resolved += s
    end

    resolved
  end


  private


  def self._resolve_reference(reference, env)
    if !reference.is_a?(Hash) || !reference.has_key?('ref')
      return reference
    end

    if JSONModel.parse_reference(reference['ref'])
      record = resolve_uri(reference['ref'], env)
      reference.clone.merge('_resolved' => ASUtils.json_parse(record))
    else
      raise "Couldn't parse ref: #{reference.inspect}"
    end
  end



end
