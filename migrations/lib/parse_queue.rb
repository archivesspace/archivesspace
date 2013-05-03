module ASpaceImport
  

  # Manages the JSON object batch set
  
  class Batch < Array
    attr_accessor :links

    def initialize(opts)
      @opts = opts
      @dupes = {}

      @must_be_unique = ['subject']

      @uri_remapping = {}
      @seen_records = {}
    end
     
    def push(obj)
      hash = obj.to_hash(:raw)

      if @must_be_unique.include?(hash['jsonmodel_type'])
        hash_code = hash.clone.tap {|h| h.delete("uri")}.hash

        if @seen_records[hash_code]
          # Duplicate detected.  Map this record's URI back to the first instance we saw.
          $stderr.puts("FOUND A DUPE")
          @uri_remapping[hash['uri']] = @seen_records[hash_code]
        else
          @seen_records[hash_code] = hash['uri']
        end
      end

      super(hash)
    end

    
    def save
      repo_id = Thread.current[:selected_repo_id]
      batch = []
      
      while self.size > 0
        rec = self.shift
        batch << ASpaceImport::Utils.update_record_references(rec, @uri_remapping)
      end

      uri = "/repositories/#{repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      
      if @opts[:dry]        
        
        response = mock('Net::HTTPResponse')
        
        res_body = "{\"saved\":{"
        batch.each_with_index do |hsh, i|
          res_body << "," unless i == 0
          res_body << "\"#{hsh['uri']}\":\"#{hsh['uri']}\""
        end
        res_body << "}}"
        
        res_body
        
        response.stubs(:code => 200, :body => res_body)
        
        response
        
      else
        json = ASUtils.to_json(batch)

        JSONModel::HTTP.with_request_priority(:low) do
          JSONModel::HTTP.post_json(url, json)
        end
      end
    end
    
  end

  
  class ParseQueue < Array

    def initialize(opts)
      @batch = Batch.new(opts) 
      @dupes = {}
      @opts = opts
    end
    
    def pop

      if self.last.class.method_defined? :uri and !self.last.uri.nil?
        @batch.push(self.last) unless self.last.uri.nil?
      end      
      
      super
      
    end
    
    
    def <<(obj)
      push(obj)
    end
    
    
    def push(obj)
      @selected = obj      
      super 
    end


    def save
      while self.length > 0
        @opts[:log].warn("Pushing a queued object to the batch before saving")
        self.pop
      end
      @batch.save
    end

    
    def inspect
      "Parse Queue: " << super <<  " -- Batch: " << @batch.inspect
    end
    
  end
end



