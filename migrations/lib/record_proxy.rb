module ASpaceImport

  class RecordProxyMgr

    def initialize
      @proxies = {}
    end


    def get_proxy_for(proxy_key, record_type = nil)

      unless @proxies.has_key?(proxy_key)
        @proxies[proxy_key] = RecordProxy.new(proxy_key, record_type)
      end

      @proxies[proxy_key]
    end


    # the object appears, and the proxy can be
    # discharged
    def discharge_proxy(proxy_key, proxied_obj)
      if @proxies.has_key?(proxy_key)
        @proxies[proxy_key].discharge(proxied_obj)
        @proxies.delete(proxy_key)
      end
    end


    def undischarged
      undis = []
      @proxies.each do |type, proxy|
        unless proxy.discharged
          undis << proxy
        end
      end
      undis
    end
  end


  # This object can temporarily represent a JSONModel object
  # in streaming contexts where, for example, an object may
  # not be ready to link to other objects (because it's not
  # valid yet) or may not even be ready to be an object of
  # a particular type. The proxy can handle object creation
  # or can just act as a store for delayed jobs.

  class RecordProxy
    attr_reader :discharged
    attr_reader :key

    def initialize(key, record_type = nil)
      @key = key
      @jobs = []
      @spawn_callbacks = []
      @discharged = false
      @data = {}
      if record_type
        @record_type = record_type
      end
    end


    def to_s
      type = @record_type && !@record_type.respond_to?(:call) ? @record_type : "Anonymous or Typeless Object"
      "Record Proxy for <#{type}>"
    end


    def set(k, v)
      @data[k] = v
    end


    def method_missing(meth)
      @data.has_key?(meth.to_s) ? @data[meth.to_s] : nil
    end


    def spawn

      raise "Can't spawn an object because record type is unknown" unless @record_type
      type = @record_type.respond_to?(:call) ? @record_type.call(@data) : @record_type
      
      return nil unless type

      obj = ASpaceImport::JSONModel(type).new
      obj.key = @key
      @data.each do |k,v|

        next unless obj.class.schema['properties'].has_key?(k)

        property_type = ASpaceImport::Utils.get_property_type(obj.class.schema['properties'][k])
        filtered_val = ASpaceImport::Utils.value_filter(property_type[0]).call(v)

        if property_type[0] =~ /_list$/
          obj.send(k) << filtered_val
        else
          obj.send("#{k}=", filtered_val)
        end
      end

      @spawn_callbacks.each do |callback|
        callback.call(@data, obj)
      end

      obj
    end


    # jobs to run after spawning an object
    def on_spawn(callback)
      @spawn_callbacks << callback
    end


    # jobs to run when discharged by the importer
    def on_discharge(receiver, method, *args)
      @jobs << Proc.new {|obj| receiver.send(method, *args, obj)}
    end


    def discharge(proxied_obj)
      @jobs.each {|proc| proc.call(proxied_obj) }
      @discharged = true
    end
  end
end
