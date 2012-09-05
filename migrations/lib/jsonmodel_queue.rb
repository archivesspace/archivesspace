module JSONModel
  module Client

    @@queue = Array.new # JSON objects waiting for all their properties
    @@aux_queue = Array.new # JSON objects waiting for another JSON object to be saved
    
    def self.queue
      @@queue
    end
    
    def add_after_save_hook(proc)
      @after_save_hooks ||= Array.new
      @after_save_hooks.push(proc)
    end
    
    def after_save
      @after_save_hooks.each { |proc| proc.call } if @after_save_hooks    
    end
    
    # Add a reference to a json_object that will
    # need to be saved before self can be saved.
    # A referenced object should have an after_save
    # hook to update this reference.
    
    def add_reference(json_obj)
      @required_references ||= Array.new
      @required_references.push(json_obj)
    end
    
    
    def references
      @required_references ||= Array.new
      @required_references
    end

    
    def try_save(opts)
      can_save = true
      self.references.each do |ref|
        can_save = false unless ref.uri 
      end    
      if can_save 
        self.save(opts) 
      else
        can_save
      end
    end  
    
    
    def enqueue
      @@queue.push(self)
    end
    
    # Try to save the JSON object, do some post-save updating
    # of related objects if it works, then remove it from the 
    # main queue.
    
    # TODO - get repo_id from the opts
    def dequeue
      # save_now = true
      # self.class.schema['properties'].each do |a|
      #   
      #   # check if it has a property that depends on another JSON object
      #   # if it does, then it must be saved later.
      #   # TODO - it could be set already, so the value should actually be checked
      #   if self.send(a[0]).class.to_s.match(/^JSONModel/) #ugly
      #     save_now = false 
      #   end
      # end
      
      # if save_now
      if self.try_save({:repo_id => '1'})
        self.after_save
        @@aux_queue.each_index do |i|        
          if @@aux_queue[i].try_save
            @@aux_queue[i] = nil
          end
        end
        @@aux_queue.compact!
      else
        @@aux_queue.push(self)
      end  
      @@queue.pop
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
#         puts self.last.to_s
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
#           puts "Saving #{self.last.to_s}"
#           saved_key = @json_queue.last.save({:repo_id => '1'})
#           puts "Saved #{saved_key}"
#           #saved_key = rand(26)
#         
#         
#           # Go through the shadow queue and save anything that can be saved
#           @shadow_queue.each do |jo|
#             jo.last.class.schema['properties'].each do |a|
#               if jo.send(a[0]).class.to_s.match(/^SJONModel/)
#                 puts "REference #{jo.send(a[0]).to_s}"
#               end
#             end
#           end
#         end
#         super
#       end
#     end
#   end
# end