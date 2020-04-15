module RESTHelpers

  include JSONModel


  module ResponseHelpers

    def json_response(obj, status = 200)
      [status, {"Content-Type" => "application/json"}, [obj.to_json(:mode => :trusted, :max_nesting => false) + "\n"]]
    end


    def modified_response(type, obj, jsonmodel = nil)
      response = {:status => type, :id => obj[:id], :lock_version => obj[:lock_version], :stale => obj.system_modified?}

      if jsonmodel
        response[:uri] = jsonmodel.class.uri_for(obj[:id], params)
        response[:warnings] = jsonmodel._warnings
      end

      json_response(response)
    end


    def created_response(*opts)
      modified_response('Created', *opts)
    end


    def updated_response(*opts)
      modified_response('Updated', *opts)
    end

    def deleted_response(id)
      json_response({:status => 'Deleted', :id => id})
    end


    def suppressed_response(id, state)
      json_response({:status => 'Suppressed', :id => id, :suppressed_state => state})
    end


    def moved_response(id, target)
      json_response({:status => 'Moved', :id => id, :target => target.id})
    end

  end


  class Endpoint
    @@endpoints = []


    @@param_types = {
      :repo_id => [Integer,
                   "The Repository ID",
                   {:validation => ["The Repository must exist", ->(v){Repository.exists?(v)}]}],
      :resolve => [[String], "A list of references to resolve and embed in the response",
                   :optional => true],
      :id => [Integer, "The ID of the record"]
    }

    @@return_types = {
      :created => '{:status => "Created", :id => (id of created object), :warnings => {(warnings)}}',
      :updated => '{:status => "Updated", :id => (id of updated object)}',
      :suppressed => '{:status => "Suppressed", :id => (id of updated object), :suppressed_state => (true|false)}',
      :error => '{:error => (description of error)}'
    }

    def initialize(method)
      @methods = ASUtils.wrap(method)
      @uri = ""
      @description = "-- No description provided --"
      @documentation = nil
      @prepend_to_autodoc = true
      @examples = {}
      @permissions = []
      @preconditions = []
      @required_params = []
      @paginated = false
      @paged = false
      @use_transaction = :unspecified
      @returns = []
      @request_context_keyvals = {}
    end

    def [](key)
      if instance_variable_defined?("@#{key}")
        instance_variable_get("@#{key}")
      end
    end


    def self.all
      @@endpoints.map do |e|
        e.instance_eval do
          {
            :uri => @uri,
            :description => @description,
            :documentation => @documentation,
            :prepend_docs => @prepend_to_autodoc,
            :examples => @examples,
            :method => @methods,
            :params => @required_params,
            :paginated => @paginated,
            :paged => @paged,
            :returns => @returns
          }
        end
      end
    end


    def self.get(uri); self.method(:get).uri(uri); end
    def self.post(uri); self.method(:post).uri(uri); end
    def self.delete(uri); self.method(:delete).uri(uri); end
    def self.get_or_post(uri); self.method([:get, :post]).uri(uri); end
    def self.method(method); Endpoint.new(method); end

    # Helpers
    def self.is_toplevel_request?(env)
      env["ASPACE_REENTRANT"].nil?
    end

    def self.is_potentially_destructive_request?(env)
      env["REQUEST_METHOD"] != "GET"
    end


    def uri(uri); @uri = uri; self; end
    def description(description); @description = description; self; end
    def preconditions(*preconditions); @preconditions += preconditions; self; end

    # For the following methods (documentation, example),  content can be provided via either
    # argument or as the return value of a provided block.

    # Add documentation for endpoint to be interpolated into the API docs.
    # If "prepend" is true, the automated docs (e.g. pagination) will be
    #   appended to this when API docs are generated, otherwise this will
    #   replace the docs entirely.
    #
    # Note: If you make prepend false, you should provide __Parameters__
    #       and __Returns__ sections manually.
    #
    # Recommended usage:
    #
    # endpoint.documentation do
    #   <<~DOCS
    #   # Header
    #   Some content
    #   - with maybe a list
    #   - who doesn't like lists, right?
    #   DOCS
    # end
    def documentation(docs = nil, prepend: true)
      if block_given?
        docs = yield docs, prepend
      end
      if docs
        @documentation = docs
        @prepend_to_autodoc = prepend
      end

      self
    end

    # Add an example to the example code tabs.
    #
    # The highlighter argument must be a language code understood by the rouge highlighting library
    #   (https://github.com/jneen/rouge/wiki/List-of-supported-languages-and-lexers)
    #
    # Recommended usage:
    #
    # endpoint.example('shell') do
    #   <<~CONTENTS
    #   wget 'blah blah blah'
    #   CONTENTS
    # end
    def example(highlighter, contents = nil)
      if block_given?
        contents = yield contents
      end
      if contents
        contents = <<~TEMPLATE
          ```#{highlighter}
          #{contents}
          ```
        TEMPLATE

        @examples[highlighter] = contents
      end
      self
    end


    def permissions(permissions)
      @has_permissions = true

      permissions.each do |permission|
        @preconditions << proc { |request| current_user.can?(permission) }
      end

      self
    end


    def request_context(hash)
      @request_context_keyvals = hash

      self
    end


    def params(*params)
      @required_params = params.map do |p|
        param_name, param_type = p

        if @@param_types[param_type]
          # This parameter type has a standard definition
          defn = @@param_types[param_type]
          [param_name, *defn]
        else
          p
        end
      end

      self
    end


    def deprecated(description = nil)
      @deprecated = true
      @deprecated_description = description

      self
    end

    def paginated(val)
      @paginated = val

      self
    end

    def paged(val)
      @paged = val

      self
    end


    def use_transaction(val)
      @use_transaction = val

      self
    end


    def returns(*returns, &block)
      raise "No .permissions declaration for endpoint #{@methods.map{|m|m.to_s.upcase}.join('|')} #{@uri}" if !@has_permissions

      @returns = returns.map { |r| r[1] = @@return_types[r[1]] || r[1]; r }

      @@endpoints << self

      preconditions = @preconditions
      rp = @required_params
      paginated = @paginated
      paged = @paged
      deprecated = @deprecated
      deprecated_description = @deprecated_description
      use_transaction = @use_transaction
      uri = @uri
      methods = @methods
      request_context = @request_context_keyvals

      if ArchivesSpaceService.development?
        # Undefine any pre-existing routes (sinatra reloader seems to have trouble
        # with this for our instances)
        ArchivesSpaceService.instance_eval {
          new_route = compile(uri)

          methods.each do |method|
            if @routes[method.to_s.upcase]
              @routes[method.to_s.upcase].reject! do |route|
                route[0..1] == new_route
              end
            end
          end
        }
      end

      methods.each do |method|
        ArchivesSpaceService.send(method, @uri, {}) do
          if deprecated
            Log.warn("\n" +
                     ("*" * 80) +
                     "\n*** CALLING A DEPRECATED ENDPOINT: #{method} #{uri}\n" +
                     (deprecated_description ? ("\n" + deprecated_description) : "") +
                     "\n" +
                     ("*" * 80))
          end


          RequestContext.open(request_context) do
            DB.open do |db|
              ensure_params(rp, paginated, paged)
            end

            Log.debug("Post-processed params: #{Log.filter_passwords(params).inspect}")

            RequestContext.put(:repo_id, params[:repo_id])
            RequestContext.put(:is_high_priority, high_priority_request?)

            if Endpoint.is_toplevel_request?(env) || Endpoint.is_potentially_destructive_request?(env)
              unless preconditions.all? { |precondition| self.instance_eval &precondition }
                raise AccessDeniedException.new("Access denied")
              end
            end

            use_transaction = (use_transaction == :unspecified) ? true : use_transaction
            db_opts = {}

            if use_transaction
              if methods == [:post]
                # Pure POST requests use read committed so that tree position
                # updates can be retried with a chance of succeeding (i.e. we
                # can read the last committed value when determining our
                # position)
                db_opts[:isolation_level] = :committed
              else
                # Anything that might be querying the DB will get repeatable read.
                db_opts[:isolation_level] = :repeatable
              end
            end

            DB.open(use_transaction, db_opts) do
              RequestContext.put(:current_username, current_user.username)

              # If the current user is a manager, show them suppressed records
              # too.
              if RequestContext.get(:repo_id)
                if current_user.can?(:index_system)
                  # Don't mess with the search user
                  RequestContext.put(:enforce_suppression, false)
                else
                  RequestContext.put(:enforce_suppression,
                                     !((current_user.can?(:manage_repository) ||
                                        current_user.can?(:view_suppressed) ||
                                        current_user.can?(:suppress_archival_record)) &&
                                       Preference.defaults['show_suppressed']))
                end
              end

              self.instance_eval &block
            end
          end
        end
      end
    end
  end


  class NonNegativeInteger
    def self.value(s)
      val = Integer(s)

      if val < 0
        raise ArgumentError.new("Invalid non-negative integer value: #{s}")
      end

      val
    end
  end


  class PageSize
    def self.value(s)
      val = Integer(s)

      if val < 0
        raise ArgumentError.new("Invalid non-negative integer value: #{s}")
      end

      if val > AppConfig[:max_page_size].to_i
        Log.warn("Requested page size of #{val} exceeds the maximum allowable of #{AppConfig[:max_page_size]}." +
                 "  It has been reduced to the maximum.")

        val = AppConfig[:max_page_size].to_i
      end

      val
    end
  end


  class IdSet
    def self.value(val)
      vals = val.is_a?(Array) ? val : val.split(/,/)

      result = vals.map {|elt| Integer(elt)}.uniq

      if result.length > AppConfig[:max_page_size].to_i
        raise ArgumentError.new("ID set cannot contain more than #{AppConfig[:max_page_size]}n IDs")
      end

      result
    end
  end


  class BooleanParam
    def self.value(s)
      if s.nil?
        nil
      elsif s.downcase == 'true'
        true
      elsif s.downcase == 'false'
        false
      else
        raise ArgumentError.new("Invalid boolean value: #{s}")
      end
    end
  end


  class UploadFile
    def self.value(val)
      OpenStruct.new(val)
    end
  end


  def self.included(base)

    base.extend(JSONModel)

    base.helpers do

      def coerce_type(value, type)
        if type == Integer
          Integer(value)
        elsif type == DateTime
          DateTime.parse(value)
        elsif type == Date
          Date.parse(value)
        elsif type.respond_to? :from_json

          # Allow the request to specify how the incoming JSON is encoded, but
          # convert to UTF-8 for processing
          if request.content_charset
            value = value.force_encoding(request.content_charset).encode("UTF-8")
          end

          type.from_json(value)
        elsif type.is_a? Array
          if value.is_a? Array
            value.map {|elt| coerce_type(elt, type[0])}
          else
            raise ArgumentError.new("Not an array")
          end
        elsif type.is_a? Regexp
          raise ArgumentError.new("Value '#{value}' didn't match #{type}") if value !~ type
          value
        elsif type.respond_to? :value
          type.value(value)
        elsif type == String
          value
        elsif type == :body_stream
          value
        else
          raise BadParamsException.new("Type not recognized: #{type}")
        end
      end


      def process_pagination_params(params, known_params, errors, paged)
        known_params['resolve'] = known_params['modified_since'] = true

        params['modified_since'] = coerce_type((params[:modified_since] || '0'),
                                              NonNegativeInteger)

        if params[:page]
          known_params['page_size'] = known_params['page'] = true
          params['page_size'] = coerce_type((params[:page_size] || AppConfig[:default_page_size]), PageSize)
          params['page'] = coerce_type(params[:page], NonNegativeInteger)

        elsif params[:id_set]
          known_params['id_set'] = true
          params['id_set'] = coerce_type(params[:id_set], IdSet)

        elsif params[:all_ids]
          params['all_ids'] = known_params['all_ids'] = true

        else
          # paged and paginated routes both support accessing results a page at a time,
          #   via the page and page_size arguments
          # paginated routes additionally support:
          #   - fetching all database ids as an array via all_ids
          #   - fetching a set of specific known ids via id_set
          if paged
            # Must provide page
            errors[:missing] << {
              :name => 'page',
              :doc => "Must provide 'page' (a number)"
            }
          else
            # Must provide either page, id_set or all_ids
            ['page', 'id_set', 'all_ids'].each do |name|
              errors[:missing] << {
                :name => name,
                :doc => "Must provide either 'page' (a number), 'id_set' (an array of record IDs), or 'all_ids' (a boolean)"
              }
            end
          end
        end
      end


      def process_indexed_params(name, params)
        if params[name] && params[name].is_a?(Hash)
          params[name] = params[name].sort_by(&:first).map(&:last)
        end
      end


      def process_declared_params(declared_params, params, known_params, errors)
        declared_params.each do |definition|

          (name, type, doc, opts) = definition
          opts ||= {}

          if (type.is_a?(Array))
            process_indexed_params(name, params)
          end

          known_params[name] = true

          if opts[:body]
            params[name] = request.body.read
          elsif type == :body_stream
            params[name] = request.body
          end

          if not params[name] and !opts[:optional] and !opts.has_key?(:default)
            errors[:missing] << {:name => name, :doc => doc}
          else

            if type and params[name]
              begin
                params[name.intern] = coerce_type(params[name], type)
                params.delete(name)

              rescue ArgumentError
                errors[:bad_type] << {:name => name, :doc => doc, :type => type}
              end
            elsif type and opts[:default]
              params[name.intern] = opts[:default]
              params.delete(name)
            end

            if opts[:validation]
              if not opts[:validation][1].call(params[name.intern])
                errors[:failed_validation] << {:name => name, :doc => doc, :type => type, :validation => opts[:validation][0]}
              end
            end

          end
        end
      end


      def ensure_params(declared_params, paginated, paged)

        errors = {
          :missing => [],
          :bad_type => [],
          :failed_validation => []
        }

        known_params = {}

        process_declared_params(declared_params, params, known_params, errors)
        process_pagination_params(params, known_params, errors, paged) if paginated || paged

        # Any params that were passed in that aren't declared by our endpoint get dropped here.
        unknown_params = params.keys.reject {|p| known_params[p.to_s] }

        unknown_params.each do |p|
          params.delete(p)
        end


        if not errors.values.flatten.empty?
          result = {}

          errors[:missing].each do |missing|
            result[missing[:name]] = ["Parameter required but no value provided"]
          end

          errors[:bad_type].each do |bad|
            provided_value = params[bad[:name]]
            msg = "Wanted type #{bad[:type]} but got '#{provided_value}'"


            if bad[:type].is_a?(Array) &&
               !provided_value.is_a?(Array) &&
               provided_value.is_a?(bad[:type][0])
              # The caller got the right type but didn't wrap it in an array.
              # Provide a more useful error message.
              msg << ".  Perhaps you meant to specify an array like: #{bad[:name]}[]=#{URI.escape(provided_value)}"
            end

            result[bad[:name]] = [msg]
          end

          errors[:failed_validation].each do |failed|
            result[failed[:name]] = ["Failed validation -- #{failed[:validation]}"]
          end

          raise BadParamsException.new(result)
        end
      end
    end
  end

end
