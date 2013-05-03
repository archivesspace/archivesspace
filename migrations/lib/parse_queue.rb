module ASpaceImport
  

  # Manages the JSON object batch set
  
  class Batch < Array
    attr_accessor :links
    @must_be_unique = ['subject']


    def initialize(opts)
      @opts = opts
      @dupes = {}
    end
     
    def push(obj)
      @dupes.merge!(self.class.find_dupe(obj, self) || {})
      super
    end
    
    def dedupe
      #1. Remove objects that duplicate earlier objects
      @dupes.each do |uri2drop, uri2keep|
        @opts[:log].warn("Dropping dupe: #{uri2drop}")
        self.reject! {|obj| obj.uri == uri2drop}
      end
      
      #2. Update links in the remaining set
      self.each do |json|
        ASpaceImport::Utils.update_record_references(json, @dupes) {|uri| uri}
      end
      
    end
    
    def save

      # TODO - making a flag for this could make things faster for some
      self.dedupe
      
      repo_id = Thread.current[:selected_repo_id]
      batch = []
      
      while self.size > 0
        batch << self.shift.to_hash(:raw)
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
    
    # Check the batch to see if any record
    # is a match for the added record.   
    def self.find_dupe(json, batch)

      return nil unless @must_be_unique.include?(json.jsonmodel_type.to_s)
      
      batch.each do |bjson|

        next unless json.jsonmodel_type == bjson.jsonmodel_type
      
        next unless json.to_hash.size == bjson.to_hash.size
      
        diff = bjson.to_hash.to_a - json.to_hash.to_a
        if diff.length == 1
          raise "Unanticipated Hash Difference" unless diff[0][0] == 'uri'
          return {json.uri => bjson.uri}
        end
      end
      nil
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



