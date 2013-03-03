module ASpaceImport
  
  
  # Wrap the batch model so dynamic enums don't raise errors
  def self.BatchModel
    
    cls = Class.new(JSONModel::JSONModel(:batch_import)) do
  
      # Need to bypass some validation rules for 
      # JSON objects created by an import
      def self.validate(hash)
        begin
          super(hash)
        rescue JSONModel::ValidationException => e

          e.errors.reject! {|path, mssg| 
                            e.attribute_types.has_key?(path) && 
                            e.attribute_types[path] == 'ArchivesSpaceDynamicEnum'}
                          
          raise e unless e.errors.empty?

        end
      end
    end
    
    cls
  end
  
  
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
        self.reject! {|obj| obj.uri == uri2drop}
      end
      
      #2. Update links in the remaining set
      self.each do |json|
        ASpaceImport::Crosswalk.update_record_references(json, @dupes) {|uri| uri}
      end
      
    end
    
    def save

      self.dedupe
      
      batch_object = ASpaceImport.BatchModel.new #BatchModel.new
      repo_id = Thread.current[:selected_repo_id]
      batch = []
      
      self.each do |obj|
        batch << obj.to_hash(:raw)
      end
      batch_object.set_data({:batch => batch})

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
        JSONModel::HTTP.with_request_priority(:low) do
          JSONModel::HTTP.post_json(url, batch_object.to_json(:max_nesting => false))
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
      @repo_id = opts[:repo_id] if opts[:repo_id]
      @batch = Batch.new(opts) 
      @dupes = {}
    end
    
    def select_each_and(&dothis)
      self.reverse.each do |obj|
        self.selected=obj
        dothis.call
      end
      self.selected = self.last
    end
    
    def with_raised(&dothis)
      if self.raised.length
        self.raised.each do |auf|
          self.selected=auf
          dothis.call
        end
        self.selected = self.last
      end
    end
    
    def iterate
      self.reverse.each_with_index do |json, i|
        self.selected=self[i]
        yield json
      end
    end
    
    def pop

      self[0...-1].reverse.each do |qdobj|
      
        # Set Links FROM popped object TO other objects in the queue
        self.last.receivers.for_obj(qdobj) do |r|  
          r << qdobj
        end
      
        # Set Links TO the popped object FROM others in the queue
      
        qdobj.receivers.for_obj(self.last) do |r|
          r << self.last
        end
         
      end
      
      # If the object has a uri, send it to the POST batch; otherwise
      # it's an inline record.
      if self.last.class.method_defined? :uri and !self.last.uri.nil?
        @batch.push(self.last) unless self.last.uri.nil?
      end      
      
      super
      
      @selected = self.last
    end
    
    def <<(obj)
      push(obj)
    end
    
    def push(obj)
      raise "Not a JSON Object" unless obj.class.record_type
      @selected = obj
      
      super 
    end
    
    def push_and_raise(obj)
      self.push(obj)
      self.raised.push(self.last)
    end
    
    def unraise_all
      @raised = []
    end

    def save
      @batch.save
    end
    
    def inspect
      "Parse Queue: " << super <<  " -- Batch: " << @batch.inspect
    end
    
    def selected
      @selected ||= self.last
    end
    
    def raised
      @raised ||= []
    end
    
    protected
    
    def selected=(json)
      @selected = json
    end
        
  end
end



