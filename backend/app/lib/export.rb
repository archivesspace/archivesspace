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
    
  end
  
  # TODO - Get these methods using ExportModels...
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
  
end
  
