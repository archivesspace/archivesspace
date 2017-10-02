class Resource < Sequel::Model(:resource)
  include ASModel
  corresponds_to JSONModel(:resource)

  include Identifiers
  include Subjects
  include Extents
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Instances
  include Deaccessions
  include Agents
  include Trees
  include ResourceTrees
  include Notes
  include ExternalIDs
  include CollectionManagements
  include UserDefineds
  include ComponentsAddChildren
  include Classifications
  include Transferable
  include Events
  include Publishable
  include RevisionStatements
  include ReindexTopContainers
  include RightsRestrictionNotes 
  include RepresentativeImages
  include Assessments::LinkedRecord

  enable_suppression

  tree_record_types :resource, :archival_object

  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  tree_of(:resource, :archival_object)
  set_model_scope :repository

  define_relationship(:name => :spawned,
                      :json_property => 'related_accessions',
                      :contains_references_to_types => proc {[Accession]})


  repo_unique_constraint(:ead_id,
                         :message => "Must be unique",
                         :json_property => :ead_id)


  # Maintain a finding_aid_sponsor_sha1 column to allow us to do quick lookups for OAI.
  def self.create_from_json(json, opts = {})
    sponsor = {}

    if json.finding_aid_sponsor
      sponsor[:finding_aid_sponsor_sha1] = Digest::SHA1.hexdigest(json.finding_aid_sponsor)
    end

    super(json, opts.merge(sponsor))
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    sponsor = {}

    if json.finding_aid_sponsor
      sponsor[:finding_aid_sponsor_sha1] = Digest::SHA1.hexdigest(json.finding_aid_sponsor)
    else
      sponsor[:finding_aid_sponsor_sha1] = nil
    end

    super(json, opts.merge(sponsor), apply_nested_records)
  end


  def self.id_to_identifier(id)
    res = Resource[id]
    [res[:id_0], res[:id_1], res[:id_2], res[:id_3]].compact.join(".")
  end

  # For resources, we want the level returned in our ordered_record response
  def self.ordered_record_properties(record_ids)
    result = super.clone

    self.filter(:id => record_ids).select(:id, :level_id, :other_level).each do |row|
      id = row[:id]
      level = if row[:other_level]
                row[:other_level]
              else
                BackendEnumSource.value_for_id('archival_record_level', row[:level_id])
              end

      result[id] ||= {}
      result[id][:level] = level
    end

    result
  end

end
