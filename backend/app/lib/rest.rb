module RESTHelpers

  include JSONModel

  class Endpoint

    @@endpoints = []

    def initialize(method)
      @method = method
      @required_params = []
      @returns = []
    end

    def self.method(method); Endpoint.new(method); end

    def uri(uri); @uri = uri; self; end
    def params(*params); @required_params = params; self; end

    def returns(*returns, &block)
      @returns = returns;

      @@endpoints << self

      rp = @required_params
      ArchivesSpaceService.send(@method, @uri, {}) do
        ensure_params(rp)
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
                params[name.intern] = if type == Integer
                                        Integer(params[name])
                                      elsif type.respond_to? :from_json
                                        type.from_json(params[name])
                                      else
                                        params[name]
                                      end
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
