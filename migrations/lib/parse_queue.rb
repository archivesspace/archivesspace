require 'tempfile'

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

      @backing_file = Tempfile.new("import_batch")
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

    
    def save
      @backing_file.close

      repo_id = Thread.current[:selected_repo_id]
      batch = Tempfile.new("import_batch")
      
      batch.write("[")

      uris = []
      File.open(@backing_file.path).each_with_index do |line, i|
        batch.write(",") unless i == 0

        rec = ASUtils.json_parse(line)
        rec = ASpaceImport::Utils.update_record_references(rec, @uri_remapping)

        uris << rec['uri']

        batch.write(ASUtils.to_json(rec))
      end

      @backing_file.unlink

      batch.write("]")
      batch.close

      uri = "/repositories/#{repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      
      if @opts[:dry]        
        batch.unlink

        response = mock('Net::HTTPResponse')
        
        res_body = "{\"saved\":{"
        uris.each_with_index do |uri, i|
          res_body << "," unless i == 0
          res_body << "\"#{uri}\":\"#{uri}\""
        end
        res_body << "}}"
        
        res_body
        
        response.stubs(:code => 200, :body => res_body)
        
        response
        
      else
        begin
          JSONModel::HTTP.with_request_priority(:low) do
            JSONModel::HTTP.post_json_file(url, batch.path)
          end
        ensure
          batch.unlink
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



