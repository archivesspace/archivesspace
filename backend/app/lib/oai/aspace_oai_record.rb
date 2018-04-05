require_relative 'mappers/oai_dc'
require_relative 'mappers/oai_dcterms'
require_relative 'mappers/oai_mods'

class ArchivesSpaceOAIRecord

  attr_reader :sequel_record, :jsonmodel_record

  def initialize(sequel_record, jsonmodel_record)
    @jsonmodel_record = JSONModel::JSONModel(:resource).new(
        URIResolver.resolve_references( jsonmodel_record, ['repository', 'linked_agents', 'subjects', 'digital_object', 'top_container', 'top_container::container_profile'] ))

    JSONModel::set_publish_flags!(@jsonmodel_record)
    @sequel_record = sequel_record
  end

  def id
    @jsonmodel_record.uri
  end

  def to_oai_ead
    raise OAI::FormatException.new unless @jsonmodel_record['jsonmodel_type'] == 'resource'

    RequestContext.open(:repo_id => @sequel_record.repo_id) do
      ead = ASpaceExport.model(:ead).from_resource(@jsonmodel_record, @sequel_record.tree(:all, mode = :sparse), {})

      record = []
      ASpaceExport::stream(ead).each do |chunk|
        record << chunk
      end

      remove_xml_declaration(record.join(""))
    end
  end

  def to_oai_marc
    RequestContext.open(:repo_id => @sequel_record.repo_id) do
      marc = ASpaceExport.model(:marc21).from_resource(@jsonmodel_record)
      remove_xml_declaration(ASpaceExport::serialize(marc))
    end
  end

  def to_oai_dc
    OAIDCMapper.new.map_oai_record(self)
  end

  def to_oai_dcterms
    OAIDCTermsMapper.new.map_oai_record(self)
  end

  def to_oai_mods
    OAIMODSMapper.new.map_oai_record(self)
  end

  def updated_at
    @sequel_record.system_mtime
  end

  private

  def remove_xml_declaration(s)
    if s.start_with?('<?xml ')
      # Discard the declaration
      s[s.index("?>") + 2..-1]
    else
      s
    end
  end

end
