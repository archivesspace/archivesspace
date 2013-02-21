require_relative "../../../migrations/lib/exporter"

module ExportHelpers
  
  ASpaceExport::init unless ASpaceExport::initialized?
 
  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end
  
  def generate_ead(id, type, repo_id)

    # todo: generalize this for other types
    resource = Resource.get_or_die(id)
    
    serializer = ASpaceExport::serializer(:ead)
    
    serializer.repo_id = repo_id

    serializer.serialize(resource, {:repo_id => repo_id})
  end
  
  def generate_eac(id, type)
    
    agent = Kernel.const_get(type.camelize).get_or_die(id)
    
    serializer = ASpaceExport::serializer(:eac)
    
    # serializer.repo_id = repo_id
    
    serializer.serialize(agent)
  end
end
  
