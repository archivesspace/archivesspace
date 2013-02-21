require_relative "../../../migrations/lib/exporter"

module ExportHelpers
  
  ASpaceExport::init unless ASpaceExport::initialized?
 
  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end
  
  def generate_mods(id)
    
    obj = DigitalObject.get_or_die(id)
    
    mods_data = ASpaceExport.model(:mods).from_digital_object(obj)
    
    ASpaceExport.serializer(:mods).serialize(mods_data)
    
    # re = RelatedExporter.new(obj)
    # 
    # serializer = ASpaceExport.serializer(:mods)
    # 
    # serializer.set(:@digital_object, DigitalObject.to_jsonmodel(obj))
    #     
    # re.related do |variable, array|
    #   serializer.set(:"@#{variable}", array)
    # end
    #   
    # serializer.set(:@digital_object_tree, obj.tree)    
    # 
    # serializer.serialize
    
  end
  
  def generate_ead(id, type, repo_id)

    resource = Resource.get_or_die(id)
    
    serializer = ASpaceExport::serializer(:ead)
    
    serializer.repo_id = repo_id

    serializer.serialize(resource, {:repo_id => repo_id})
  end
  
  def generate_eac(id, type)
    
    agent = Kernel.const_get(type.camelize).get_or_die(id)
    
    serializer = ASpaceExport::serializer(:eac)
    
    serializer.serialize(agent)
  end
  
  class RelatedExporter
    
    def initialize(obj)
      @obj = obj
    end
    
    def related
      @obj.class.instance_variable_get(:@relationships).each do |relationship|
        records = @obj.my_relationships(relationship[:name]).map do |rel|
          json = rel[1].class.to_jsonmodel(rel[1])
          
          case relationship[:name]
          when :linked_agents
            json['role'] = rel[0]['role']
          end
          
          json
        end

        yield relationship[:json_property], records
        # yield relationship[:json_property], @obj.my_relationships(relationship[:name]).map {|rel| rel[1].class.to_jsonmodel(rel[1])}
      end
    end     
  
  end
  
  class MODS
    
    def from_digital_object(obj)
      
    end 
      
  end    
  
  
end
  
