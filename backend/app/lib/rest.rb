module RESTHelpers

  include JSONModel


  def resolve_references(json, resolve)
    hash = json.to_hash

    (resolve or []).each do |property|
      if hash[property]
        if hash[property].is_a? Array
          hash[property] = hash[property].map do |uri|
            JSON(redirect_internal(uri)[2].join(""))
          end
        else
          hash[property] = JSON(redirect_internal(hash[property])[2].join(""))
        end
      end
    end

    hash
  end


  class Endpoint

    @@endpoints = []

    @@return_types = {
      :created => '{:status => "Created", :id => [id of created object]}'
    }

    def initialize(method)
      @method = method
      @uri = ""
      @description = "-- No description provided --"
      @required_params = []
      @returns = []
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
    def params(*params); @required_params = params; self; end

    def returns(*returns, &block)

      returns.map { |r| r[1] = @@return_types[r[1]] or r[1] }
      @returns = returns

      @@endpoints << self

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

        if self.class.development?
          Log.debug("#{method.to_s.upcase} #{uri}")
          Log.debug("Request parameters: #{params.inspect}")
        end

        self.instance_eval &block
      end
    end
  end


  def self.included(base)

    base.extend(JSONModel)

    base.helpers do
      def base.endpoint
        endpoint = Endpoint.new

        @@endpoints << endpoint

        endpoint
      end


      def coerce_type(value, type)
        if type == Integer
          Integer(value)
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
          :bad_type => []
        }

        declared_params.each do |definition|

          (name, type, doc, opts) = definition
          opts ||= {}

          if opts[:body]
            params[name] = request.body.read
          end

          if not params[name] and not opts[:optional]
            errors[:missing] << {:name => name, :doc => doc}
          else

            if type and params[name]
              begin
                params[name.intern] = coerce_type(params[name], type)
                params.delete(name)

              rescue ArgumentError
                errors[:bad_type] << {:name => name, :doc => doc, :type => type}
              end
            end

          end
        end

        if not errors.values.flatten.empty?
          s = "Your request parameters weren't quite right:\n\n"

          errors[:missing].each do |missing|
            s += "  * Missing value for '#{missing[:name]}' -- #{missing[:doc]}\n"
          end

          errors[:bad_type].each do |bad|
            s += "  * Invalid type for '#{bad[:name]}' -- Wanted type #{bad[:type]} but got '#{params[bad[:name]]}'\n"
          end

          raise MissingParamsException.new(s)
        end
      end
    end
  end

end
