module JSONModel
  module Client

    class ParseQueue < Array
      @repo_id = '1'
      def pop
        if self.length > 0
          self.last.save_or_wait({:repo_id => @repo_id})        
          super
        end
      end
      
      def init(opts)
        @repo_id = opts[:repo_id] if opts[:repo_id]
      end
    end

    @@queue = ParseQueue.new # JSON objects waiting for all their data to stream
    @@wait_queue = Array.new # JSON objects waiting for another JSON object to be saved

    
    def self.queue(opts)
      @@queue.init(opts)
      @@queue
    end
    
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
  
    
    def enqueue
      @@queue.push(self)
    end
    
    # Try to save the JSON object, do some post-save updating
    # of related objects if it works, then remove it from the 
    # main queue.
    

    # TODO - get repo_id from the opts
    def save_or_wait(opts = {:repo_id => '1'})
      repo_id = opts[:repo_id]
      if self.try_save(opts)
        @@wait_queue.each_index do |i|        
          @@wait_queue[i] = nil if @@wait_queue[i].try_save({:repo_id => repo_id})
        end
        @@wait_queue.compact!
      else
        @@wait_queue.push(self)
      end
    end

 
    # Protected methods
    protected
     
    def try_save(opts = {:repo_id => '1'})
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

# module ASpaceImport
#   class JSONQueue < Array
#     include JSONModel
# 
#   
#     def initialize
#       @shadow_queue = []
#     end
# 
#   
#     def push(type)
#       if (type)
#         jo = JSONModel(type).new
#         super(jo)
#       end
#     end
# 
# 
#     def set_property(property, value)
#       if self.length > 0 and property
#         if self.last.respond_to?(property)
#           unless self.last.send("#{property}") # don't set the property more than once
#             self.last.send("#{property}=", value)
#           end
#         else
#           raise StandardError.new("Can't set #{property} on #{@self.last.to_s}")
#         end
#       end
#     end
# 
#     # Close the currently open X
#     def pop  
#       # to do - do something with type? (sanity check)
#       # actually save the json object, catch errors, etc.
#       if self.length > 0
#         strict_mode(true)
#         # are any of the properties other JSON objects? 
#         # if so, stash it in the shadow queue
#         shadow = false
#         self.last.class.schema['properties'].each do |a|
#           if self.last.send(a[0]).class.to_s.match(/^JSONModel/) #ugly
#             shadow = true
#           end
#         end
#         if shadow
#           @shadow_queue.push(self.last)
#         else
#           saved_key = @json_queue.last.save({:repo_id => '1'})
#           #saved_key = rand(26)
#         
#         
#           # Go through the shadow queue and save anything that can be saved
#           @shadow_queue.each do |jo|
#             jo.last.class.schema['properties'].each do |a|
#               if jo.send(a[0]).class.to_s.match(/^SJONModel/)
#               end
#             end
#           end
#         end
#         super
#       end
#     end
#   end
# end