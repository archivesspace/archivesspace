class EADModel < ASpaceExport::ExportModel
  model_for :ead

  include ASpaceExport::ArchivalObjectDescriptionHelpers
  include ASpaceExport::LazyChildEnumerations

  RESOLVE = ['subjects', 'linked_agents', 'digital_object', 'top_container', 'top_container::container_profile']

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


  # For a given set of ArchivalObject IDs attempt to pull the records from Solr.
  # If they're in there and are up-to-date, this saves us hitting the database.
  #
  # In the future we might want to generalize this to other record types and use
  # it elsewhere, but for now I'll let it incubate here :)
  #
  class IndexedArchivalObjectPrefetcher
    RecordVersion = Struct.new(:id, :lock_version, :position)

    def fetch(ao_ids, resolve)
      # For each record of interest, calculate its URI and obtain its latest lock_version
      # and position.
      uri_to_version = {}

      ArchivalObject.filter(:id => ao_ids).select(:id, :lock_version, :position).each do |row|
        uri = ArchivalObject.uri_for(:archival_object, row[:id])
        uri_to_version[uri] = RecordVersion.new(row[:id], row[:lock_version], row[:position])
      end

      # Try the search index
      results = Search.records_for_uris(uri_to_version.keys)
      indexed_records = results['results'].map {|result| ASUtils.json_parse(result['json'])}

      # Walk through our results and throw out any that aren't up-to-date
      good_records = []
      indexed_records.each do |indexed|
        desired_version = uri_to_version.fetch(indexed['uri']).lock_version
        indexed_version = indexed['lock_version']

        desired_position = uri_to_version.fetch(indexed['uri']).position
        indexed_position = indexed['position']

        if desired_version == indexed_version
          # Reorder mode updates the position in the database without incrementing
          # the lock_version. If position in the database is different from
          # position in the index even though the lock versions are the same, set
          # position in the good record to database position which corresponds to
          # the position from re-ordering
          indexed['position'] = desired_position if indexed_position != desired_position
          good_records << indexed
        end
      end

      uris_needing_refetch = uri_to_version.keys - (good_records.map {|json| json['uri']})

      unless uris_needing_refetch.empty?
        # We've got some records that weren't available in the index.  Plan B...
        ids_needing_refetch = uris_needing_refetch.map {|uri| uri_to_version[uri][:id]}

        objs = ArchivalObject.sequel_to_jsonmodel(ArchivalObject.filter(:id => ids_needing_refetch).all)
        good_records.concat(URIResolver.resolve_references(objs, resolve))
      end

      good_records.sort_by {|record| record.fetch('position')}
    end
  end

  @ao = Class.new do
    include ASpaceExport::ArchivalObjectDescriptionHelpers
    include ASpaceExport::LazyChildEnumerations

    def self.prefetch(tree_nodes, repo_id)
      RequestContext.open(:repo_id => repo_id) do
        # NOTE: We assume that the above `resolve` properties have also been
        # resolved by the indexer.
        IndexedArchivalObjectPrefetcher.new.fetch(tree_nodes.map {|tree| tree['id']},
                                                  RESOLVE)
      end
    end

    def self.from_prefetched(tree, rec, repo_id)
      new(tree, repo_id, rec)
    end

    def initialize(tree, repo_id, prefetched_rec = nil)
      @repo_id = repo_id
      @children = tree ? tree['children'] : []
      @child_class = self.class
      @json = nil
      RequestContext.open(:repo_id => repo_id) do
        rec = prefetched_rec || URIResolver.resolve_references(ArchivalObject.to_jsonmodel(tree['id']), RESOLVE)
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
      self.linked_agents.select {|link| ['creator', 'source'].include?(link['role']) }
    end

  end


  def initialize(obj, tree, opts)
    @json = obj
    opts.each do |k, v|
      self.instance_variable_set("@#{k}", v)
    end

    repo_ref = obj.repository['ref']
    @repo_id = JSONModel::JSONModel(:repository).id_for(repo_ref)
    @repo = Repository.to_jsonmodel(@repo_id)
    @children = tree['children']
    @child_class = self.class.instance_variable_get(:@ao)
  end


  def self.from_resource(obj, tree, opts)
    self.new(obj, tree, opts)
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


  def include_uris?
    include_uris
  end


  # Defaults to true if @include_uris is not defined or its value is nil.
  def include_uris
    if instance_variable_defined?(:@include_uris)
      @include_uris = true if @include_uris.nil?

      return @include_uris
    end

    @include_uris = true
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


  # EAD2002 address lines
  def addresslines
    agent = self.agent_representation
    return [] unless agent && agent.agent_contacts[0]

    contact = agent.agent_contacts[0]

    data = []
    (1..3).each do |i|
      data << contact["address_#{i}"]
    end

    line = ""
    line += %w(city region).map {|k| contact[k] }.compact.join(', ')
    line += " #{contact['post_code']}"
    line.strip!

    data << line unless line.empty?

    if (telephones = contact['telephones'])
      telephones.each do |t|
        phone = ''
        if t['number_type'].nil?
          phone += "#{I18n.t('repository.telephone')}: "
        else
          phone += "#{t['number_type'].capitalize} #{I18n.t('telephone.number')}: "
        end
        phone += "#{t['number']}"
        phone += " (#{I18n.t('repository.telephone_ext')}: #{t['ext']})" if t['ext']

        data << phone unless phone.empty?
      end
    end

    data << contact['email'] if contact['email']

    data.compact!

    data
  end


  # EAD3 address lines
  def addresslines_keyed
    agent = self.agent_representation
    return [] unless agent && agent.agent_contacts[0]

    contact = agent.agent_contacts[0]

    data = {}
    (1..3).each do |i|
      data["address_#{i}"] = contact["address_#{i}"]
    end

    line = ""
    line += %w(city region).map {|k| contact[k] }.compact.join(', ')
    line += " #{contact['post_code']}"
    line.strip!
    data['city_region_post_code'] = line unless line.empty?

    if (telephones = contact['telephones'])
      telephones.each_with_index do |t, i|
        data["telephone_#{i}"] = []
        if t['number_type'].nil?
          data["telephone_#{i}"] << "#{I18n.t('repository.telephone').downcase}"
        else
          data["telephone_#{i}"] << t['number_type']
        end

        data["telephone_#{i}"] << t['number']
        data["telephone_#{i}"][1] += " (#{I18n.t('repository.telephone_ext')}: #{t['ext']})" if t['ext']
      end
    end

    data['email'] = contact['email']

    data.delete_if { |k, v| v.nil? }

    data
  end


  def descrules
    return nil unless @descrules || self.finding_aid_description_rules
    @descrules ||= I18n.t("enumerations.resource_finding_aid_description_rules.#{self.finding_aid_description_rules}", :default => self.finding_aid_description_rules)
    @descrules
  end


  def creators_and_sources
    self.linked_agents.select {|link| ['creator', 'source'].include?(link['role']) }
  end


  def metadata_rights_declaration_in_publicationstmt
    must_be_empty = %w(file_uri)
    @json.metadata_rights_declarations.each do |mrd|
      next if must_be_empty.find { |property| !mrd[property].to_s.empty? }
      yield mrd
    end
  end

  def metadata_rights_declaration_in_rightsdeclaration
    must_not_be_empty = %w(file_uri)
    @json.metadata_rights_declarations.each do |mrd|
      next unless must_not_be_empty.find { |property| !mrd[property].to_s.empty? }
      yield mrd
    end
  end
end
