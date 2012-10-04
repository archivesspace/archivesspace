module JSONModel
  module Queueable
    
    # Methods to support queuing of objects that can't
    # be saved until a related object has been saved
    # and assigned a URI
          
    @@wait_queue = Array.new # JSON objects waiting for another JSON object to be saved

    def after_save(&block)
      @after_save_hooks ||= Array.new
      @after_save_hooks.push(Proc.new(&block))
    end 
  
    # Wait until another object is saved
    # before allowing itself to be saved.
    # TODO - raise an error before a deadlock
    # occurs
    
    def wait_for(json_obj)
      @waiting_for ||= Array.new
      @waiting_for.push(json_obj)
    end
    
    # Try to save the JSON object, do some post-save updating
    # of related objects if it works, then remove it from the 
    # main queue.
  
    def save_or_wait(opts = {})
      if self.try_save(opts)
        while @@wait_queue.length > 0 do
          @@wait_queue.each_index do |i|        
            @@wait_queue[i] = nil if @@wait_queue[i].try_save(opts)
          end
          break if @@wait_queue.compact! == nil
        end
      else
        @@wait_queue.push(self)
      end
    end

 
    # Protected methods
    protected
     
    def try_save(opts = {})
      can_save = true
      self.waiting_for.each do |w|
        can_save = false unless w.uri 
      end    
      if can_save
        puts self.to_s
        if opts[:dry] == true
          r = self.fake_save(opts)
        else
          r = self.save(opts)
        end
        self.run_after_save_hooks
        return r
      else
        can_save
      end
    end

    def fake_save(opts)
      id = rand(100)
      
      self.uri = self.class.uri_for(id.to_s, opts)

      # If we were able to save successfully, increment our local version
      # number to match the version on the server.
      self.lock_version = "1"
    end
    
    
    def run_after_save_hooks
      @after_save_hooks.each { |proc| proc.call } if @after_save_hooks    
    end
    
    
    def waiting_for
      @waiting_for || Array.new
    end
    
  end
end

