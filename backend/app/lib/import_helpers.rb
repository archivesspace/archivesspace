require_relative "../../../migrations/lib/crosswalk"

module ImportHelpers
  
  def handle_import
    batch = Batch.new(params[:batch_import])
    
    RequestContext.put(:repo_id, params[:repo_id])

    begin
      batch.process
      json_response({:saved => batch.saved_uris}, 200)
    end
  end
  

  class Batch
    attr_accessor :saved_uris
    
    def initialize(batch_object)
      @json_set, @as_set, @saved_uris = {}, {}, {}
      
      batch_object.batch.each do |item|
         @json_set[item['uri']] = JSONModel::JSONModel(item['jsonmodel_type']).from_hash(item, false)
      end
      
    end
      
    # 0. Add new enums till everything validates  
    # 1. Create ASModel objects from the JSONModel objects minus the references
    # 2. Update the nonce URIs of the JSONModel objects using their DB IDs
    # 3. Update JSONModel links using the real URIs
    # 4. Update ASModels with JSONModels with their references

    def process

      @second_pass_keys = []

      @json_set.each do |ref, json|
              
        # TODO: add a method to say whether a json is de-linkable

        if json.jsonmodel_type == 'collection_management'
          @second_pass_keys << ref
        else
          begin
          unlinked = self.class.unlink(json)

          obj = Kernel.const_get(json.class.record_type.camelize).create_from_json(unlinked)
          @as_set[json.uri] = [obj.id, obj.class]
        
          # Now update the URI with the real ID
          json.uri.sub!(/\/[0-9]+$/, "/#{@as_set[json.uri][0].to_s}")
          
          rescue Exception => e

            raise ImportException.new({:invalid_object => json, :error => e})
          end
        end
      end
      

      @second_pass_keys.each do |ref|
        begin
        json = @json_set[ref]
        # Update the references in json
        ASpaceImport::Crosswalk.update_record_references(json, @json_set.select{|k, v| 
          !@second_pass_keys.include?(k) 
          }) {|referenced| referenced.uri}
        
        obj = Kernel.const_get(json.class.record_type.camelize).create_from_json(json)
        @as_set[json.uri] = [obj.id, obj.class]
        
        # Now update the URI with the real ID
        json.uri.sub!(/\/[0-9]+$/, "/#{@as_set[json.uri][0].to_s}")
        @saved_uris[ref] = @json_set[ref].uri
        ASpaceImport::Crosswalk.update_record_references(json, @json_set) {|referenced| referenced.uri}
        rescue Exception => e
          raise ImportException.new({:invalid_object => json, :error => e})
        end
      end
      
      # Update the linked record pointers in the json set
      @json_set.each do |ref, json|
        next if @second_pass_keys.include?(ref)
        ASpaceImport::Crosswalk.update_record_references(json, @json_set) {|referenced| referenced.uri}
      end
      

      @as_set.each do |ref, a|
        next if @second_pass_keys.include?(ref)
        obj = a[1].get_or_die(a[0])

        obj.update_from_json(@json_set[ref], {:lock_version => obj.lock_version}) 
        @saved_uris[ref] = @json_set[ref].uri   
      end
    end    
    
    
    def self.unlink_key?(kdef, v)
      key_type = ASpaceImport::Crosswalk.get_property_type(kdef)[0]
      return true if key_type == :record_uri && v.is_a?(String) && !v.match(/\/vocabularies\/[0-9]+$/)
      return true if key_type == :record_uri_or_record_inline && v.is_a?(String)
      return true if key_type == :record_uri_or_record_inline_list && v[0].is_a?(String)
      return true if key_type.match(/^record_ref/)
      false
    end


    def self.unlink(json)
      unlinked = json.clone
      data = unlinked.to_hash
      data.each { |k, v| data.delete(k) if self.unlink_key?(json.class.schema["properties"][k], v) }
      unlinked.set_data(data)
      unlinked
    end
    
    # Assuming for now there are no arrays
    # of strings that are each enumerable, etc.
    # Just a) strings that are enumerable and 
    # b) arrays of objects with enumerable 
    # TODO: See if this method can be repurposed
    # from somewhere else
    
    def self.fetch_enum_name(json, schema_frag, path)

      if schema_frag.has_key?('properties')
        schema_frag = schema_frag['properties']
      end
      
      path = path.is_a?(Array) ? path : path.split("/")
      
      return nil unless schema_frag.has_key?(path[0])
    
      if path.length == 1 && schema_frag[path[0]].has_key?('dynamic_enum')
        return schema_frag[path[0]]['dynamic_enum']
      elsif json.nil? 
        return nil
      elsif json[path[0]].is_a?(Array) && json[path[0]][path[1].to_i].is_a?(Hash)
        sub_schema = JSONModel::JSONModel(json[path[0]][path[1].to_i]['jsonmodel_type']).schema
        fetch_enum_name(nil, sub_schema, path[2..-1])
      else 
        return nil
      end
    end
  end


  class ImportException < StandardError
    attr_accessor :invalid_object
    attr_accessor :message

    def initialize(opts)
      @invalid_object = opts[:invalid_object]
      @error = opts[:error]
      @message = @error.message
    end
    
    def to_hash
      hsh = {'record_title' => nil, 'record_type' => nil, 'error_class' => self.class.name, 'errors' => []}
      hsh['record_title'] = @invalid_object.title ? @invalid_object.title : "unknown or untitled"
      hsh['record_type'] = @invalid_object.jsonmodel_type ? @invalid_object.jsonmodel_type : "unknown type"
      
      if @error.respond_to?(:errors)
        @error.errors.each {|e| hsh['errors'] << e}
      end
      
      hsh
    end

    def to_s
      "#<:ImportException: #{{:invalid_object => @invalid_object, :error => @error}.inspect}>"
    end
  end

end


 
