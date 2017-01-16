require_relative "../exporters/lib/exporter"
require_relative 'AS_fop'


module ExportHelpers

  ASpaceExport::init
  
  def pdf_response(pdf)
    [status, {"Content-Type" => "application/pdf"}, pdf ]
  end
  
  def generate_pdf_from_ead( ead )
    xml = ""
    ead.each { |e| xml << e  }
    ASFop.new(xml).to_pdf
  end

  def xml_response(xml)
    [status, {"Content-Type" => "application/xml"}, [xml + "\n"]]
  end


  def stream_response(streamer, content_type = "application/xml")
    [status, {"Content-Type" => content_type}, streamer]
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


  def generate_ead(id, include_unpublished, include_daos, use_numbered_c_tags)
    obj = resolve_references(Resource.to_jsonmodel(id), ['repository', 'linked_agents', 'subjects', 'tree', 'digital_object'])
    opts = {
      :include_unpublished => include_unpublished,
      :include_daos => include_daos,
      :use_numbered_c_tags => use_numbered_c_tags
    }

    ead = ASpaceExport.model(:ead).from_resource(JSONModel(:resource).new(obj), opts)
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

    repo_json = Repository.to_jsonmodel(RequestContext.get(:repo_id))
    repo = JSONModel(:repository).new(repo_json)

    eac = ASpaceExport.model(:eac).from_agent(JSONModel(type.intern).new(obj), events, related_records, repo)
    ASpaceExport::serialize(eac)
  end

  # this takes identifiers and makes sure there's no 'funny' characters.
  # usefuly for filenaming on exports.
  def safe_filename(id, suffix = "")
    filename = "#{id}_#{Time.now.getutc}_#{suffix}" 
    filename.gsub(/\s+/, '_').gsub(/[^0-9A-Za-z_\.]/, '')
  end


end
