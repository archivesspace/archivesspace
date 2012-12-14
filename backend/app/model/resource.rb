require_relative 'notes'

class Resource < Sequel::Model(:resource)
  include ASModel
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
  include Notes

  tree_of(:resource, :archival_object)
  set_model_scope :repository
  corresponds_to JSONModel(:resource)


  def self.set_related_accession(json, opts)
    opts["accession_id"] = nil

    if json.related_accession
      opts["accession_id"] = parse_reference(json.related_accession, opts)[:id]
    end
  end


  def self.create_from_json(json, opts = {})
    set_related_accession(json, opts)
    super
  end


  def update_from_json(json, opts = {})
    self.class.set_related_accession(json, opts)
    super
  end


  def link(opts)
    child = ArchivalObject.get_or_die(opts[:child])
    child.resource_id = self.id
    child.parent_id = opts[:parent]
    child.save
  end


  def children
    ArchivalObject.filter(:resource_id => self.id, :parent_id => nil).order(:position)
  end


  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super
    json.related_accession = uri_for(:accession, obj.accession_id) if obj.accession_id
    json
  end


  def self.records_matching(query, max)
    self.this_repo.where(Sequel.like(Sequel.function(:lower, :title),
                                     "#{query}%".downcase)).first(max)
  end


end
