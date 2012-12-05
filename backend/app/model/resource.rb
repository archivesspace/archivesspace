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

  many_to_many :accession, :join_table => :accession_resource


  def self.set_related_accessions(obj, json, opts)
    if json.related_accessions
      json.related_accessions.each do |uri|
        accession_id = parse_reference(uri, opts)[:id]

        obj.add_accession(Accession[accession_id])
      end
    end
  end


  def self.create_from_json(json, opts = {})
    obj = super
    set_related_accessions(obj, json, opts)
    obj
  end


  def update_from_json(json, opts = {})
    obj = super
    self.class.set_related_accessions(obj, json, opts)
    obj
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
    json.related_accessions = obj.accession.map { |acc| self.uri_for(:accession, acc.id) }
    json
  end


  def self.records_matching(query, max)
    self.this_repo.where(Sequel.like(Sequel.function(:lower, :title),
                                     "#{query}%".downcase)).first(max)
  end


end
