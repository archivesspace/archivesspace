module URIResolver

  include JSONModel

  # Resolve any references of the form {'ref' => '/my/uri'} in any property of
  # 'value' contained in 'properties_to_resolve'.
  #
  # The elements in 'properties_to_resolve' can be simple string properties, or
  # structured properties like:
  #
  #  one::two::three
  #
  # This syntax will cause the "one" ref to be resolved, then the "two" ref to
  # be resolved within its resolved document, followed by the "three" ref.
  #
  def self.resolve_references(value, properties_to_resolve, env)
    if properties_to_resolve.is_a?(Array)
      properties = properties_to_resolve.map {|p| p.split(/::/)}
    end

    resolve_references_helper(value, properties, env)
  end


  def self.resolve_references_helper(value, properties_to_resolve, env)
    value = value.to_hash(:trusted) if value.is_a?(JSONModelType)

    # If ASPACE_REENTRANT is set, don't resolve anything or we risk creating loops.
    return value if (properties_to_resolve.nil? || env['ASPACE_REENTRANT'])

    if value.is_a? Hash
      if value.has_key?('ref') && properties_to_resolve == :all
        resolve_reference(value, env)
      else
        result = value.clone

        value.each do |k, v|
          if properties_to_resolve.is_a?(Array) && properties_to_resolve.any? {|p| p.first == k}
            wants_array = v.is_a? Array

            subproperties = properties_to_resolve.map {|p|
              (p.first == k) ? p.drop(1) : nil
            }.compact

            resolved = (v.is_a?(Array) ? v : [v]).map {|elt|
              resolve_reference(elt, env).tap do |r|
                r['_resolved'] = resolve_references_helper(r['_resolved'], subproperties, env)
              end
            }

            result[k] = wants_array ? resolved : resolved.first
          else
            result[k] = resolve_references_helper(v, properties_to_resolve, env)
          end
        end

        result
      end


    elsif value.is_a? Array
      value.map {|elt| resolve_references_helper(elt, properties_to_resolve, env)}
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
        repo_uri = JSONModel.repository_for(uri)
        repo_id = repo_uri ? JSONModel::JSONModel(:repository).id_for(repo_uri) : nil

        RequestContext.open(:repo_id => repo_id) do
          begin
            return model.to_jsonmodel(id).to_json(:mode => :trusted)
          rescue NotFoundException => e
            return nil
          end
        end
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


  def self.resolve_reference(reference, env)
    if !reference.is_a?(Hash) || !reference.has_key?('ref')
      return reference
    end

    if JSONModel.parse_reference(reference['ref'])
      record = resolve_uri(reference['ref'], env)
      if record
        reference.clone.merge('_resolved' => ASUtils.json_parse(record))
      else
        reference.clone
      end
    else
      raise "Couldn't parse ref: #{reference.inspect}"
    end
  end

end
