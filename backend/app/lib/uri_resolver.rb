module URIResolver

  include JSONModel

  class URIResolver

    include JSONModel

    def initialize(properties_to_resolve, env)
      @to_resolve = []
      @env = env

      if properties_to_resolve.is_a?(Array)
        @properties = properties_to_resolve
      else
        raise ":all not implemented yet"
      end
    end


    # Walk 'value', find all refs, resolve them
    def resolve_references(value, clone = true)
      return value if properties.empty?

      value = value.to_hash(:trusted) if value.is_a?(JSONModelType)
      value = deep_clone(value) if clone

      @to_resolve = []

      # Walk the tree of 'value' looking for any refs that should be resolved.
      # Store them on this instance.
      store_refs_for_resolving(value)

      # Resolve all refs, mutating 'value' to include resolved versions.
      resolve_and_insert_refs!

      value
    end


    private

    def store_refs_for_resolving(value)
      if value.is_a?(Hash)
        value.each do |k, v|
          if !properties_matching(k).empty?
            as_array(v).each do |elt|
              mark_for_resolving(elt, properties_matching(k)) if reference?(elt)
            end
          else
            store_refs_for_resolving(v)
          end
        end
      elsif value.is_a? Array
        value.each do |elt|
          store_refs_for_resolving(elt)
        end
      end
    end


    def reference?(val)
      val.is_a?(Hash) && val.has_key?('ref')
    end


    def deep_clone(value)
      Marshal.load(Marshal.dump(value))
    end


    def as_array(v)
      (v.is_a?(Array) ? v : [v])
    end


    def mark_for_resolving(ref, matching_properties)
      matching_properties.each do |properties|
        @to_resolve << {
          :ref => ref,
          :after_resolve => proc {
            if properties.length > 1
              self.class.new([properties.drop(1)], env).resolve_references(ref['_resolved'], false)
            end
          }
        }
      end
    end


    def find_model_by_jsonmodel_type(type)
      ASModel.all_models.find {|model|
        jsonmodel = model.my_jsonmodel(true)
        jsonmodel && jsonmodel.record_type == type
      }
    end


    def group_resolve_requests(requests)
      grouped = {}

      # Group resolve requests by model and then by repository.
      requests.each do |request|
        ref = request[:ref]

        # type, id, repo_uri
        parsed = JSONModel.parse_reference(ref['ref'])
        repo_id = parsed[:repository] ? JSONModel(:repository).id_for(parsed[:repository]) : nil

        model = find_model_by_jsonmodel_type(parsed[:type])

        grouped[model] ||= {}
        grouped[model][repo_id] ||= []

        request[:id] = parsed[:id]
        grouped[model][repo_id] << request
      end

      # Turn the requests into a flat structure like:
      #
      #  [[model1, repo_id1, [r1, r2, r3]], ...]
      #
      result = []
      grouped.each do |model, repo_requests|
        repo_requests.each do |repo_id, requests|
          result << [model, repo_id, requests]
        end
      end

      result
    end


    def resolve_and_insert_refs!
      group_resolve_requests(@to_resolve).each do |model, repo_id, requests|
        if model
          RequestContext.open(:repo_id => repo_id) do
            id_to_request = {}
            requests.each do |request|
              id_to_request[request[:id]] ||= []
              id_to_request[request[:id]] << request
            end

            objs = model.filter(:id => id_to_request.keys).all
            jsons = model.sequel_to_jsonmodel(objs)

            objs.zip(jsons).each do |obj, json|
              requests = id_to_request[obj.id]
              requests.each do |request|
                request[:ref]['_resolved'] ||= json.to_hash(:trusted)
                request[:after_resolve].call
              end
            end
          end
        else
          # For records we didn't find a model for, we do it the old-fashioned way
          requests.each do |request|
            ref = request[:ref]

            uri = ref['ref']
            response = ::URIResolver.forward_rack_request("GET", uri, env)
            resolved = ""

            response[2].each do |s|
              resolved += s
            end

            resolved = ASUtils.json_parse(resolved)

            if resolved
              ref['_resolved'] ||= resolved
            end

            request[:after_resolve].call
          end
        end
      end
    end


    def properties_matching(key)
      properties.select {|p| p.first == key}
    end

    attr_reader :env, :properties

  end


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


  def self.resolve_references(value, properties_to_resolve, env)
    # If ASPACE_REENTRANT is set, don't resolve anything or we risk creating
    # loops.
    return value if (properties_to_resolve.nil? || env['ASPACE_REENTRANT'])

    properties = Array(properties_to_resolve).map {|p| p.split(/::/)}
    URIResolver.new(properties, env).resolve_references(value)
  end

  def resolve_references(*args)
    ::URIResolver.resolve_references(*args, env)
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

end
