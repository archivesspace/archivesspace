class EADModel < ASpaceExport::ExportModel
  model_for :ead

  include ASpaceExport::ArchivalObjectDescriptionHelpers
  include ASpaceExport::LazyChildEnumerations

  @data_src = Class.new do
    def initialize(json)
      @json = json
    end


    def method_missing(meth)
      if @json.respond_to?(meth)
        @json.send(meth)
      elsif @json.is_a?(Hash) && @json.has_key?("#{meth.to_s}")
        @json["#{meth.to_s}"]
      else
        nil
      end
    end
  end


  def self.data_src(json)
    @data_src.new(json)
  end


  @ao = Class.new do
    include ASpaceExport::ArchivalObjectDescriptionHelpers
    include ASpaceExport::LazyChildEnumerations

    def self.prefetch(tree_nodes, repo_id)
      RequestContext.open(:repo_id => repo_id) do
        objs = ArchivalObject.sequel_to_jsonmodel(ArchivalObject.filter(:id => tree_nodes.map {|tree| tree['id']}).order(:position).all)
        URIResolver.resolve_references(objs, ['subjects', 'linked_agents', 'digital_object'])
      end
    end

    def self.from_prefetched(tree, rec, repo_id)
      new(tree, repo_id, rec)
    end

    def initialize(tree, repo_id, prefetched_rec = nil)
      @repo_id = repo_id
      # @tree = tree
      @children = tree ? tree['children'] : []
      @child_class = self.class
      @json = nil
      RequestContext.open(:repo_id => repo_id) do
        rec = prefetched_rec || URIResolver.resolve_references(ArchivalObject.to_jsonmodel(tree['id']), ['subjects', 'linked_agents', 'digital_object'])
        @json = JSONModel::JSONModel(:archival_object).new(rec)
      end
    end

    def method_missing(meth, *args)
      if @json.respond_to?(meth)
        @json.send(meth, *args)
      else
        nil
      end
    end


    def creators_and_sources
      self.linked_agents.select{|link| ['creator', 'source'].include?(link['role']) }
    end
  end


  def initialize(obj, opts)
    @json = obj
    opts.each do |k, v|
      self.instance_variable_set("@#{k}", v)
    end
    repo_ref = obj.repository['ref']
    @repo_id = JSONModel::JSONModel(:repository).id_for(repo_ref)
    @repo = Repository.to_jsonmodel(@repo_id)
    @children = @json.tree['_resolved']['children']
    @child_class = self.class.instance_variable_get(:@ao)
  end


  def self.from_resource(obj, opts)
    self.new(obj, opts)
  end


  def method_missing(meth)
    if self.instance_variable_get("@#{meth.to_s}")
      self.instance_variable_get("@#{meth.to_s}")
    elsif @json.respond_to?(meth)
      @json.send(meth)
    else
      nil
    end
  end


  def include_unpublished?
    @include_unpublished
  end


  def include_daos?
    @include_daos
  end


  def use_numbered_c_tags?
    @use_numbered_c_tags
  end


  def mainagencycode
    @mainagencycode ||= repo.country && repo.org_code ? [repo.country, repo.org_code].join('-') : nil
    @mainagencycode
  end


  def agent_representation
    return false unless @repo['agent_representation_id']

    agent_id = @repo['agent_representation_id']
    json = AgentCorporateEntity.to_jsonmodel(agent_id)

    json
  end


  def addresslines
    agent = self.agent_representation
    return [] unless agent && agent.agent_contacts[0]

    contact = agent.agent_contacts[0]

    data = []
    (1..3).each do |i|
      data << contact["address_#{i}"]
    end

    line = ""
    line += %w(city region).map{|k| contact[k] }.compact.join(', ')
    line += " #{contact['post_code']}"
    line.strip!

    data <<  line unless line.empty?

    %w(telephone email).each do |property|
      data << contact[property]
    end

    data.compact!

    data
  end


  def descrules
    return nil unless @descrules || self.finding_aid_description_rules
    @descrules ||= I18n.t("enumerations.resource_finding_aid_description_rules.#{self.finding_aid_description_rules}", :default => self.finding_aid_description_rules)
    @descrules
  end


  def instances_with_containers
    self.instances.select{|inst| inst['container']}.compact
  end


  def creators_and_sources
    self.linked_agents.select{|link| ['creator', 'source'].include?(link['role']) }
  end


  def digital_objects
    if @include_daos
      self.instances.select{|inst| inst['digital_object']}.compact.map{|inst| inst['digital_object']['_resolved'] }.compact
    else
      []
    end
  end
end
