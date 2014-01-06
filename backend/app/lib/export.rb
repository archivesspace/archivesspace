require_relative "../migrations/lib/exporter"

module ExportHelpers

  ASpaceExport::init unless ASpaceExport::initialized?

  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end


  def stream_response(streamer)
    [status, {"Content-Type" => "application/xml"}, streamer]
  end


  def tsv_response(tsv)
    [status, {"Content-Type" => "text/tab-separated-values"}, [tsv + "\n"]]
  end


  def generate_labels(id)
    obj = resolve_references(Resource.to_jsonmodel(id), ['tree', 'repository'])
    labels = ASpaceExport.model(:labels).from_resource(JSONModel(:resource).new(obj))
    ASpaceExport.serializer(:tsv).serialize(labels)
  end


  def generate_dc(id)
    obj = resolve_references(DigitalObject.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects'])
    dc = ASpaceExport.model(:dc).from_digital_object(JSONModel(:digital_object).new(obj))
    ASpaceExport.serializer(:dc).serialize(dc)
  end


  def generate_mets(id)
    obj = resolve_references(DigitalObject.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects', 'tree'])
    mets = ASpaceExport.model(:mets).from_digital_object(JSONModel(:digital_object).new(obj))
    ASpaceExport.serializer(:mets).serialize(mets)
  end


  def generate_mods(id)
    obj = resolve_references(DigitalObject.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects', 'tree'])
    mods = ASpaceExport.model(:mods).from_digital_object(JSONModel(:digital_object).new(obj))
    ASpaceExport.serializer(:mods).serialize(mods)
  end


  def generate_marc(id)
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects'])
    marc = ASpaceExport.model(:marc21).from_resource(JSONModel(:resource).new(obj))
    ASpaceExport.serializer(:marc21).serialize(marc)
  end

  # streamin'
  def generate_ead(id, unpublished)
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects', 'tree', 'digital_object'])
    ead = ASpaceExport.model(:ead).from_resource(JSONModel(:resource).new(obj))
    ead.include_unpublished(unpublished)
    ASpaceExport.serializer(:ead).stream(ead)
  end


  def generate_eac(id, type)
    obj = Kernel.const_get(type.camelize).get_or_die(id)
    events = []

    # Events related to the 'maintenance history' of this agent record
    RequestContext.in_global_repo do
      Event.instances_relating_to(obj).each do |e|
        if obj[:repo_id] == RequestContext.get(:repo_id)
          res = resolve_references(Event.to_jsonmodel(e), ['linked_agents'])
          events << JSONModel(:event).new(res)
        end
      end
    end

    json = obj.class.to_jsonmodel(obj)
    eac = ASpaceExport.model(:eac).from_agent(json, events)
    ASpaceExport::serializer(:eac).serialize(eac)
  end

end

