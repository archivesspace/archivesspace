require_relative "../exporters/lib/exporter"

module ExportHelpers

  ASpaceExport::init

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
    ASpaceExport::serialize(labels, :serializer => :tsv)
  end


  def generate_dc(id)
    obj = resolve_references(DigitalObject.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects'])
    dc = ASpaceExport.model(:dc).from_digital_object(JSONModel(:digital_object).new(obj))
    ASpaceExport::serialize(dc)
  end


  def generate_mets(id)
    obj = resolve_references(DigitalObject.to_jsonmodel(id), ['repository::agent_representation', 'linked_agents', 'subjects', 'tree'])
    mets = ASpaceExport.model(:mets).from_digital_object(JSONModel(:digital_object).new(obj))
    ASpaceExport::serialize(mets)
  end


  def generate_mods(id)
    obj = resolve_references(DigitalObject.to_jsonmodel(id), ['repository::agent_representation', 'linked_agents', 'subjects', 'tree'])
    mods = ASpaceExport.model(:mods).from_digital_object(JSONModel(:digital_object).new(obj))
    ASpaceExport::serialize(mods)
  end


  def generate_marc(id)
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects'])
    marc = ASpaceExport.model(:marc21).from_resource(JSONModel(:resource).new(obj))
    ASpaceExport::serialize(marc)
  end


  def generate_ead(id, unpublished)
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects', 'tree', 'digital_object'])
    ead = ASpaceExport.model(:ead).from_resource(JSONModel(:resource).new(obj))
    ead.include_unpublished(unpublished)
    ASpaceExport::stream(ead)
  end


  def generate_eac(id, type)
    klass = Kernel.const_get(type.camelize)
    events = []

    agent = klass.get_or_die(id)
    relationship_defn = klass.find_relationship(:linked_agents)

    related_records = relationship_defn.find_by_participant(agent).map{|relation|
      related_record = relation.other_referent_than(agent)

      next unless [Resource, ArchivalObject, DigitalObject, DigitalObjectComponent].include?(related_record.class)

      RequestContext.open(:repo_id => related_record.repo_id) do
        {
          :role => BackendEnumSource.values_for_ids(relation[:role_id])[relation[:role_id]],
          :record => related_record.class.to_jsonmodel(related_record, :skip_relationships => true)
        }
      end
    }.compact

    obj = resolve_references(klass.to_jsonmodel(agent), ['related_agents'])

    eac = ASpaceExport.model(:eac).from_agent(JSONModel(type.intern).new(obj), events, related_records)
    ASpaceExport::serialize(eac)
  end

end
