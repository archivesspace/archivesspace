require_relative "../../../migrations/lib/exporter"

module ExportHelpers
  
  ASpaceExport::init unless ASpaceExport::initialized?
 
  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end

  def generate_dc(id)
    
    obj = DigitalObject.get_or_die(id)
    
    dc = ASpaceExport.model(:dc).from_digital_object(obj)
    
    ASpaceExport.serializer(:dc).serialize(dc)
  end

  
  def generate_mets(id)
    
    obj = DigitalObject.get_or_die(id)
    
    mets = ASpaceExport.model(:mets).from_digital_object(obj)
    
    ASpaceExport.serializer(:mets).serialize(mets)
  end
  
  
  def generate_mods(id)
    
    obj = DigitalObject.get_or_die(id)
    
    mods = ASpaceExport.model(:mods).from_digital_object(obj)
    
    ASpaceExport.serializer(:mods).serialize(mods)
  end  
  
  def generate_marc(id)
    
    # Maybe we should just have an 'all' for resolve to avoid having to list these...
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects'])
    

    marc = ASpaceExport.model(:marc21).from_resource(JSONModel(:resource).new(obj))
    
    ASpaceExport.serializer(:marc21).serialize(marc)
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
  
