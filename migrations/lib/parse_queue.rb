module ASpaceImport
  class ParseQueue < Array

    def initialize(opts)
      @repo_id = opts[:repo_id] if opts[:repo_id]
      @opts = opts
      @subqueue = Array.new # JSON objects waiting to be sent in a batch    
    end
    
    # @subqueue can be serialized to a file if necessary.
    
    def pop
      if self.length > 0
        @subqueue.push(self.last)
        super
      end
    end
    
    def push(obj)
      
      raise "Not a JSON Object" unless obj.class.record_type

      self.reverse.each do |qdobj|

        # Links FROM incoming object TO other objects in the queue
        obj.receivers.for(:depth => qdobj.depth, 
                          :xpath => qdobj.class.xpath) do |r|

          r.receive(qdobj.uri)
        end
        
        # Links TO the incoming object FROM others in the queue
        qdobj.receivers.for(:depth => obj.depth, 
                          :xpath => obj.class.xpath) do |r|
          r.receive(obj.uri)
        end
        
      end

      super
    end
    
    # Yield receivers for anything in the parse queue.
    
    def receivers(node_args)  
      self.reverse.each do |obj|        
        obj.receivers.for(node_args) { |r| yield r }
      end
    end
      
    def save
      batch_object = JSONModel::JSONModel(:batch_import).new
      repo_id = Thread.current[:selected_repo_id]

      batch = []

      @subqueue.each do |obj|
        batch << obj.to_hash(true)
      end
      batch_object.set_data({:batch => batch})

      uri = "/repositories/#{repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      
      if @opts[:dry]
        "POST \n #{batch_object.to_json}"
      else
        response = JSONModel::HTTP.post_json(url, batch_object.to_json)

        response
      end
    end
  end
end



