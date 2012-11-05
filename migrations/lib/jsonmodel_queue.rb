module JSONModel
  module Queueable
    
    # Methods to support queuing of objects that can't
    # be saved until a related object has been saved
    # and assigned a URI
          
    @@wait_queue = Array.new # JSON objects waiting for another JSON object to be saved

    def self.save_all
      request_wrapper = {:jsonmodel_type => 'batch', :payload => []}
      @@wait_queue.each do |obj|
        request_wrapper[:payload] << obj.to_hash(true)
      end
      puts "COMBINED REQUEST" if $DEBUG
      puts request_wrapper.inspect if $DEBUG
      
      uri = "/imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      puts "URL: #{url}"
      
      response = JSONModel::HTTP.post_json(url, request_wrapper.to_json)
      
      puts "RESPONSE \n #{response.inspect}" if $DEBUG
    end

    def after_save(&block)
      @after_save_hooks ||= Array.new
      @after_save_hooks.push(Proc.new(&block))
    end 
  
    # Wait until another object is saved
    # before allowing itself to be saved.
    # TODO - raise an error before a deadlock
    # occurs
    
    
    # Try to save the JSON object, do some post-save updating
    # of related objects if it works, then remove it from the 
    # main queue.
  
    def save_or_wait
      @@wait_queue.push(self)
    end

    def unsaveable?
      @unsaveable || false
    end
 
    # Protected methods
    protected
    
    def run_after_save_hooks(save_result)
      @after_save_hooks.each { |proc| proc.call(save_result) } if @after_save_hooks
      save_result  
    end   
    
    def waiting_for
      @waiting_for || Array.new
    end
    
    def unsaveable!
      @unsaveable = true
    end
    
  end
end

