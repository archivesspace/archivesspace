require 'tempfile'

module ASpaceImport
  

  # Manages the JSON object batch set
  
  class Batch < Array
    attr_accessor :repo_id

    def initialize(opts = {})
      @opts = opts
      @repo_id = Thread.current[:selected_repo_id]

      @must_be_unique = ['subject']

      @uri_remapping = {}
      @seen_records = {}

      @backing_file = Tempfile.new("import_batch")
    end
     
    def <<(obj)
      push(obj)
    end 

    def push(obj)
      hash = obj.to_hash(:raw)

      if @must_be_unique.include?(hash['jsonmodel_type'])
        hash_code = hash.clone.tap {|h| h.delete("uri")}.hash

        if @seen_records[hash_code]
          # Duplicate detected.  Map this record's URI back to the first instance we saw.
          @uri_remapping[hash['uri']] = @seen_records[hash_code]
          return
        else
          @seen_records[hash_code] = hash['uri']
        end
      end

      @backing_file.write(ASUtils.to_json(hash))
      @backing_file.write("\n")
    end

    def close

      @backing_file.close

      @batch_file = Tempfile.new("import_batch")

      @batch_file.write("[")

      uris = []
      File.open(@backing_file.path).each_with_index do |line, i|
        @batch_file.write(",") unless i == 0

        rec = ASUtils.json_parse(line)
        rec = ASpaceImport::Utils.update_record_references(rec, @uri_remapping)

        uris << rec['uri']

        @batch_file.write(ASUtils.to_json(rec))
      end

      @backing_file.unlink

      @batch_file.write("]")
      @batch_file.close
    end

    
    def save(&response_handler)

      self.close
      
      if @opts[:dry]
        
        batch = ASUtils.json_parse(File.open(@batch_file).read)
        @batch_file.unlink
                
        mapping = {:saved => Hash[batch.map {|rec| [rec['uri'], [rec['uri'], JSONModel.parse_reference(rec['uri'])[:id]]] }] }
            
        response = mock('Net::HTTPResponse')
        
        response.stubs(:code => 200, :body => ASUtils.to_json(mapping))
        
        response
        
      else
        begin
          uri = "/repositories/#{@repo_id}/batch_imports"
          url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
          
          JSONModel::HTTP.with_request_priority(:low) do
            JSONModel::HTTP.post_json_file(url, @batch_file.path, &response_handler)
          end
        ensure
          @batch_file.unlink
        end
      end
    end
    
  end

  
  class ParseQueue < Array

    def initialize(opts)
      @batch = Batch.new(opts) 
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


    def save(&block)
      while self.length > 0
        @opts[:log].warn("Saving a queued object that was not explicitly batched")
        self.pop
      end
      @batch.save(&block)
    end

    
    def inspect
      "Parse Queue: " << super <<  " -- Batch: " << @batch.inspect
    end
    
  end
end



