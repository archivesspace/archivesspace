module RESTHelpers

  include JSONModel


  def resolve_reference(uri)
    if !JSONModel.parse_reference(uri).nil?
      JSON(redirect_internal(uri)[2].join(""))
    else
      uri
    end
  end

  def resolve_references(value, properties_to_resolve)
    return value if properties_to_resolve.nil?

    if value.is_a? Hash
      resolved = {}

      value.each do |k, v|
        if properties_to_resolve.include?(k)
          resolved[k] = (v.is_a? Array) ? v.map {|elt| resolve_reference(elt)} : resolve_reference(v)
        else
          resolve_references(v, properties_to_resolve)
        end
      end

      value['resolved'] = resolved if !resolved.empty?

    elsif value.is_a? Array
      value.each {|elt| resolve_references(elt, properties_to_resolve)}
    end

    value
  end


  class Endpoint

    @@endpoints = []


    @@param_types = {
      :repo_id => [Integer,
                   "The Repository ID",
                   {:validation => ["The Repository must exist", ->(v){Repository.exists?(v)}]}]
    }

    @@return_types = {
      :created => '{:status => "Created", :id => (id of created object), :warnings => {(warnings)}}',
      :updated => '{:status => "Updated", :id => (id of updated object)}',
      :error => '{:error => (description of error)}'
    }

    def initialize(method)
      @method = method
      @uri = ""
      @description = "-- No description provided --"
      @preconditions = []
      @required_params = []
      @returns = []
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
            :method => @method,
            :params => @required_params,
            :returns => @returns
          }
        end
      end
    end

    def self.get(uri); self.method(:get).uri(uri); end
    def self.post(uri); self.method(:post).uri(uri); end
    def self.method(method); Endpoint.new(method); end

    def uri(uri); @uri = uri; self; end
    def description(description); @description = description; self; end
    def preconditions(*preconditions); @preconditions += preconditions; self; end

    def params(*params)
      @required_params = params.map do |p|
        @@param_types[p[1]] ? [p[0], @@param_types[p[1]]].flatten : p
      end

      # A special case for repo_id since it's so prevalent: if the repo_id is
      # provided, add a check to make sure the requesting user has permission
      # to view this repository
      if @required_params.any?{|param| param.first == 'repo_id'}
        if @method == :get
          @preconditions << proc { |request| current_user.can?(:view_repository, :repo_id => request.params[:repo_id]) }
        elsif @method == :post
          @preconditions << proc { |request| current_user.can?(:update_repository, :repo_id => request.params[:repo_id]) }
        end
      end

      self
    end

    def returns(*returns, &block)
      @returns = returns.map { |r| r[1] = @@return_types[r[1]] || r[1]; r }

      @@endpoints << self

      preconditions = @preconditions
      rp = @required_params
      uri = @uri
      method = @method

      if ArchivesSpaceService.development?
        # Undefine any pre-existing routes (sinatra reloader seems to have trouble
        # with this for our instances)
        ArchivesSpaceService.instance_eval {
          new_route = compile(uri)

          if @routes[method.to_s.upcase]
            @routes[method.to_s.upcase].reject! do |route|
              route[0..1] == new_route
            end
          end
        }
      end

      ArchivesSpaceService.send(@method, @uri, {}) do
        if self.class.development?
          Log.debug("#{method.to_s.upcase} #{uri}")
          Log.debug("Request parameters: #{filter_passwords(params).inspect}")
        end

        ensure_params(rp)

        Log.debug("Post-processed params: #{params.inspect}") if self.class.development?

        unless preconditions.all? { |precondition| self.instance_eval &precondition }
          raise AccessDeniedException.new("Access denied")
        end

        self.instance_eval &block
      end
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
        raise "Invalid boolean value: #{s}"
      end
    end
  end


  def self.included(base)

    base.extend(JSONModel)

    base.helpers do

      def coerce_type(value, type)
        if type == Integer
          Integer(value)
        elsif type == BooleanParam
          BooleanParam.value(value)
        elsif type.respond_to? :from_json
          type.from_json(value)
        elsif type.is_a? Array
          if value.is_a? Array
            value.map {|elt| coerce_type(elt, type[0])}
          else
            raise ArgumentError.new("Not an array")
          end
        elsif type.is_a? Regexp
          raise "Value '#{value}' didn't match #{type}" if value !~ type
          value
        else
          value
        end
      end


      def ensure_params(declared_params)

        errors = {
          :missing => [],
          :bad_type => [],
          :failed_validation => []
        }

        known_params = {}

        declared_params.each do |definition|

          (name, type, doc, opts) = definition
          opts ||= {}

          known_params[name] = true

          if opts[:body]
            params[name] = request.body.read
          end

          if not params[name] and not opts[:optional] and not opts[:default]
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
            result[bad[:name]] = ["Wanted type #{bad[:type]} but got '#{params[bad[:name]]}'"]
          end

          errors[:failed_validation].each do |failed|
            result[failed[:name]] = ["Failed validation -- #{failed[:validation]}'"]
          end

          raise BadParamsException.new(result)
        end
      end
    end
  end

end
