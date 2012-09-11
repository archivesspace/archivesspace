module JSONModel
  module Client
    
    # Chaining methods to allows an instance 
    # of a json model to provide info about 
    # its properties: TO DO - Move this to 
    # Crosswalk Class
    
    def properties
      properties_hash = self.class.schema['properties']
      cls = Class.new do
        @selected_property
        
        properties_hash.each do |prop_name, prop_defn|
          define_method prop_name do
            @selected_property = properties_hash["#{prop_name}"]
            return self
          end
        end
        
        def type 
          @selected_property['type']
        end
      end
      cls.new
        
    end
    
    # Methods to support queuing of objects that can't
    # be saved until a related object has been saved
    # and assigned a URI
          
    @@wait_queue = Array.new # JSON objects waiting for another JSON object to be saved

    def add_after_save_hook(proc)
      @after_save_hooks ||= Array.new
      @after_save_hooks.push(proc)
    end  
  
    # Wait until another object is saved
    # before allowing itself to be saved.
    
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
        r = self.save(opts)
        self.after_save
        return r
      else
        can_save
      end
    end

    
    def after_save
      @after_save_hooks.each { |proc| proc.call } if @after_save_hooks    
    end
    
    
    def waiting_for
      @waiting_for || Array.new
    end
    
  end
end

