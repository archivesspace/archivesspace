require_relative 'mappers/oai_dc'
require_relative 'mappers/oai_dcterms'

class ArchivesSpaceOAIRecord

  attr_reader :sequel_record, :jsonmodel_record

  def initialize(sequel_record, jsonmodel_record)
    @jsonmodel_record = jsonmodel_record
    @sequel_record = sequel_record
  end

  def id
    @jsonmodel_record.uri
  end

  def to_oai_ead
    raise "Only Resource records can be returned as EAD" unless @jsonmodel_record['jsonmodel_type'] == 'resource'

    RequestContext.open(:repo_id => @sequel_record.repo_id) do
      ead = ASpaceExport.model(:ead).from_resource(@jsonmodel_record, @sequel_record.tree(:all, mode = :sparse), {})

      record = []
      ASpaceExport::stream(ead).each do |chunk|
        record << chunk
      end

      result = record.join("")

      if result.start_with?('<?xml ')
        # Discard the declaration
        result[result.index("?>") + 2..-1]
      else
        result
      end
    end
  end

  def to_oai_dc
    raise "Only Archival Object records can be returned as DC" unless @jsonmodel_record['jsonmodel_type'] == 'archival_object'

    OAIDCMapper.new.map_oai_record(self)
  end

  def to_oai_dcterms
    raise "Only Archival Object records can be returned as DCTerms" unless @jsonmodel_record['jsonmodel_type'] == 'archival_object'

    OAIDCTermsMapper.new.map_oai_record(self)
  end

  def updated_at
    @sequel_record.system_mtime
  end

end
