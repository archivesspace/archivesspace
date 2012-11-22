module ASpaceImport
  
  # Manages the JSON object batch set
  # Could be folded into the JSONModel 
  # namespace.
  # Could be serialized to a file.
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
        self.reject! {|obj| obj.uri == uri2drop}
      end
      
      #2. Update links in the remaining set
      self.each do |json|
        self.class.replace_links(json, @dupes)
      end
      
    end
    
    def save

      self.dedupe
      
      batch_object = JSONModel::JSONModel(:batch_import).new
      repo_id = Thread.current[:selected_repo_id]
      batch = []
      
      self.each do |obj|
        batch << obj.to_hash(true)
      end
      batch_object.set_data({:batch => batch})

      uri = "/repositories/#{repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      
      if @opts[:dry]
        dry_response = Net::HTTPResponse.new(1.0, 200, "OK")
        
        dry_response
      else
        response = JSONModel::HTTP.post_json(url, batch_object.to_json)

        response
      end
    end
    
    # Check the batch to see if any record
    # is a match for the added record. This
    # might need to be abstracted better.    
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
    
    # Merge this into common or import and generalize for backend import
    # helpers
    def self.replace_links(json, link_map)

      data = json.to_hash
      data.each do |k, v| 
        if json.class.schema["properties"][k]["type"].match(/JSONModel/) and \
              v.is_a? String and \
              link_map.has_key?(v) and \
              v.match(/\/.*[0-9]$/) and \
              !v.match(/\/vocabularies\/[0-9]+$/)

          data[k] = link_map[v]
        elsif json.class.schema["properties"][k]["type"] == "array" and \
              !json.class.schema["properties"][k]["items"]["type"].is_a? Array and \
              json.class.schema["properties"][k]["items"]["type"].match(/JSONModel/) and \
              v.is_a? Array
          data[k] = v.map { |u| (u.is_a? String and u.match(/\/.*[0-9]$/) and link_map.has_key?(u)) ? link_map[u] : u }.uniq
        end
      end

      json.set_data(data)     
      
    end
  end
  
  class ParseQueue < Array

    def initialize(opts)
      @repo_id = opts[:repo_id] if opts[:repo_id]
      @batch = Batch.new(opts) 
      @dupes = {}  
    end
    
    def pop

      self[0...-1].reverse.each do |qdobj|
      
        # Set Links FROM popped object TO other objects in the queue
        self.last.receivers.for(qdobj.class.xpath, qdobj.depth) do |r|  
          r.receive(qdobj)
        end
        # Set Links TO the popped object FROM others in the queue
        qdobj.receivers.for(self.last.class.xpath, self.last.depth) do |r|
          r.receive(self.last)
        end          
      end
      
      # Set Default properties
      self.last.set_default_properties
      
      # If the object has a uri, send it to the POST batch; otherwise
      # it's an inline record.
      if self.last.class.method_defined? :uri and !self.last.uri.nil?
        @batch.push(self.last) unless self.last.uri.nil?
      end
      
      super
    end
    
    def push(obj)
      raise "Not a JSON Object" unless obj.class.record_type
      
      super 
    end
    
    
    # Yield receivers for anything in the parse queue.
    def receivers
      self
    end
    
    
    def for(*nodeargs)  
      self.reverse.each do |obj|        
        obj.receivers.for(*nodeargs) { |r| yield r }
      end
    end
    
 
    def save
      @batch.save
    end    
  end
end



