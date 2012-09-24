module RESTHelpers

  include JSONModel


  def resolve_references(json, resolve)
    hash = json.to_hash

    hash['resolved'] ||= {}

    (resolve or []).each do |property|
      if hash[property]
        if hash[property].is_a? Array
          hash['resolved'][property] = hash[property].map do |uri|
            JSON(redirect_internal(uri)[2].join(""))
          end
        else
          hash['resolved'][property] = JSON(redirect_internal(hash[property])[2].join(""))
        end
      end
    end

    hash
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
    def preconditions(*preconditions); @preconditions = preconditions; self; end

    def params(*params)
      @required_params = params.map do |p|
        @@param_types[p[1]] ? [p[0], @@param_types[p[1]]].flatten : p
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
        ensure_params(rp)

        unless preconditions.all? { |precondition| self.instance_eval &precondition }
          raise AccessDeniedException.new("Access denied")
        end


        if self.class.development?
          Log.debug("#{method.to_s.upcase} #{uri}")
          Log.debug("Request parameters: #{filter_passwords(params).inspect}")
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

        declared_params.each do |definition|

          (name, type, doc, opts) = definition
          opts ||= {}

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
