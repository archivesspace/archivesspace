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
      if self.try_save(opts)[0]
        while @@wait_queue.length > 0 do
          @@wait_queue.each_index do |i|        
            @@wait_queue[i] = nil if @@wait_queue[i].try_save(opts)[0]
          end
          break if @@wait_queue.compact! == nil
        end
      else
        @@wait_queue.push(self)
      end
    end

    def unsaveable?
      @unsaveable || false
    end
 
    # Protected methods
    protected
     
    def try_save(opts = {})
      puts "Trying to save: #{self.to_s}" if $DEBUG
      can_save = true
      # 1st condition allows import to proceed if 
      # a single record fails because of a validation error. 
      # Watch out for chain reactions.
      self.waiting_for.select {|w| w.unsaveable? == false && !(w.uri)}.each do |w|
        return [false]
      end    
      begin
        self.save(opts)
        save_result = [true, self.uri]
      rescue JSONModel::ValidationException
        # Here we *could* seek to recover from conflict or 
        # uniqueness exceptions by trying to find the id
        # of the dupe in the backend and proceeding
        self.unsaveable!
        save_result = [false, $!.to_s]
      end              
      self.run_after_save_hooks(save_result)
    end
    
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

