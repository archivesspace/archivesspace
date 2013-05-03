module ASpaceImport
  class RecordProxy
    attr_reader :discharged

    @proxies = {}
    
    def self.get_proxy_for(record_type, other_key = nil)
      
      proxy_key = other_key ? other_key : record_type
      
      unless @proxies.has_key?(proxy_key)
        @proxies[proxy_key] = self.new(proxy_key)
      end
    end
    
    # the object appears, and the proxy can be
    # discharged
    def self.discharge_proxy(proxy_key, proxied_obj)
      if @proxies.has_key?(proxy_key)
        @proxies[proxy_key].discharge(proxied_obj)
        @proxies.delete(proxy_key)
      end
    end
    
    
    def self.undischarged
      undis = []
      @proxies.each do |type, proxy|
        unless proxy.discharged
          undis << proxy
        end
      end
      undis
    end
    
    
    def initialize(record_type)
      @record_type = record_type
      @jobs = []
      @discharged = false
    end
    
    def to_s
      "Record Proxy for <#{@record_type}>"
    end
    
    
    def on_discharge(receiver, method, *args)   
      @jobs << Proc.new {|obj| receiver.send(method, *args, obj)}
    end
    
    
    def discharge(proxied_obj)
      @jobs.each {|proc| proc.call(proxied_obj) }
      @discharged = true
    end
    
  end
end