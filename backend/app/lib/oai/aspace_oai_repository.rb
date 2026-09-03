require_relative 'aspace_resumption_token'
require_relative 'aspace_oai_deletion'

class ArchivesSpaceOAIRepository < OAI::Provider::Model
  include JSONModel

  FormatOptions = Struct.new(:record_types, :page_size)

  def self.available_record_types
    {
      'oai_dc' => FormatOptions.new([Resource, ArchivalObject], 25),
      'oai_dcterms' => FormatOptions.new([Resource, ArchivalObject], 25),
      'oai_marc' => FormatOptions.new([Resource, ArchivalObject], 25),
      'oai_mods' => FormatOptions.new([Resource, ArchivalObject], 25),
      'oai_ead' => FormatOptions.new([Resource], 1)
    }
  end

  def get_oai_config_values
    @oai_config          = OAIConfig.all.first
    @repo_set_codes      = @oai_config[:repo_set_codes] ? JSON.parse(@oai_config[:repo_set_codes]) : []
    @sponsor_set_names   = @oai_config[:sponsor_set_names] ? JSON.parse(@oai_config[:sponsor_set_names]) : []
    @repo_description    = @oai_config[:repo_set_description]
    @sponsor_description = @oai_config[:sponsor_set_description]
    @repo_set_name       = @oai_config[:repo_set_name]
    @sponsor_set_name    = @oai_config[:sponsor_set_name]
  end

  # If a given record type supports deletes, we'll need a way to look up its
  # tombstone records.  Since we only know the URIs of those tombstones, we're
  # pretty much stuck doing slow lookups.
  def self.delete_lookups
    {
      Resource => Tombstone.where { Sequel.like(:uri, '%/resources/%') },
      ArchivalObject => Tombstone.where { Sequel.like(:uri, '%/archival_objects/%') },
    }
  end

  DELETES_PER_PAGE = 100

  RESOLVE = [
    'digital_object',
    'linked_agents',
    'repository',
    'resource',
    'subjects',
    'top_container',
    'top_container::container_profile'
  ] + AppConfig[:record_inheritance_resolves]


  def earliest
    Time.at(0).utc
  end

  def latest
    Time.now.utc
  end

  def sets
    available_levels = BackendEnumSource.values_for("archival_record_level")
    get_oai_config_values

    # ANW-674:
    # Get set values from OAIConfig table instead of config file
    config_sets = []

    if @repo_set_codes.any? && !available_levels.include?(@repo_set_name)
      repo_oai_set = OAI::Set.new({:name => @repo_set_name,
                                   :spec => @repo_set_name,
                                   :description => build_set_description(@repo_description)})

      config_sets.push(repo_oai_set)
    end

    if @sponsor_set_names.any? && !available_levels.include?(@sponsor_set_name)
      repo_sponsor_set = OAI::Set.new({:name => @sponsor_set_name,
                                       :spec => @sponsor_set_name,
                                       :description => build_set_description(@sponsor_description)})

      config_sets.push(repo_sponsor_set)
    end

    level_sets = available_levels.map {|level|
      OAI::Set.new(:name => level, :spec => level)
    }

    config_sets + level_sets.select {|s| set_enabled?(s) }
  end

  # returns true if set is enabled in at least one repository
  def set_enabled?(set)
    sets_in_repos = Repository.exclude(:publish => 0)
                              .exclude(:oai_is_disabled => 1)
                              .select(:oai_sets_available)
                              .map {|r| JSON::parse(r[:oai_sets_available]) rescue [] }

    # if oai_sets_available array is blank, then all sets are enabled for that repository.
    # if a repository is restricted to certain sets, then those set_ids will be in the oai_sets_available array.
    # So, we're looking to see if there is at least one repository with an empty set OR this set_id in the oai_sets_available array.
    set_id = BackendEnumSource.id_for_value("archival_record_level", set.name).to_s

    repos_enabling_set = sets_in_repos.select {|r| r.length == 0 || r.include?(set_id)}

    return repos_enabling_set.length > 0
  end

  def fetch_single_record(uri, options = {})
    tombstone = Tombstone.filter(:uri => uri).first

    unless tombstone.nil?
      return OAIDeletion.new(tombstone)
    end

    metadata_prefix = options.fetch(:metadata_prefix)

    format_options = options_for_type(metadata_prefix)
    parsed_ref = JSONModel.parse_reference(uri)

    raise OAI::IdException.new if parsed_ref.nil?

    model = format_options.record_types.find {|model| model.my_jsonmodel.record_type == parsed_ref.fetch(:type)}

    raise OAI::IdException.new unless model

    repo_uri = parsed_ref.fetch(:repository) { raise OAI::IdException.new }
    raise OAI::IdException.new if repo_uri.nil?

    repo_id = JSONModel.parse_reference(repo_uri).fetch(:id) { raise OAI::IdException.new }

    RequestContext.open(:repo_id => repo_id, :enforce_suppression => false) do
      obj = apply_repository_restrictions(model.filter(:id => parsed_ref[:id])).first
      raise OAI::IdException.new unless obj

      return OAIHiddenRecordDeletion.new(obj) if hidden_from_harvesters?(obj)

      json = fetch_jsonmodels(model, [obj])[0]

      return OAIHiddenRecordDeletion.new(obj) if json["has_unpublished_ancestor"]

      ArchivesSpaceOAIRecord.new(obj, json)
    end
  end

  def find(selector, options = {})
    RequestContext.open(:enforce_suppression => false) do
      if selector.is_a?(String)
        return fetch_single_record(selector, options)
      end

      resumption_token = if options.has_key?(:resumption_token)
                           ArchivesSpaceResumptionToken.parse(options.fetch(:resumption_token), ArchivesSpaceOAIRepository.available_record_types)
                         else
                           ArchivesSpaceResumptionToken.new(options, ArchivesSpaceOAIRepository.available_record_types)
                         end

      # A harvest runs through three phases: the records themselves, then the
      # tombstones of deleted records, then the records that have been hidden by
      # suppression or unpublication
      loop do
        state_before = resumption_token.state

        result = produce_next_set(resumption_token, options)

        return result if result.is_a?(Array)

        return result unless result.records.empty?

        next unless resumption_token.state == state_before

        return result unless start_next_phase!(resumption_token, options)
      end
    end
  end


  private

  def apply_repository_restrictions(dataset)
    # ANW-242: restrict excluded sets if enabled per repostiory
    # select repos that
      # -are published
      # -have OAI enabled
    # gather these repo ids and available set ids in a data structure like:
    # [ [1, [889, 886]], [2, []], ...]
    visible_repos= Repository.exclude(:publish => 0).exclude(:oai_is_disabled => 1)
                             .select(:id, :oai_sets_available)
                             .map {|row| [row[:id], row[:oai_sets_available]]}

    visible_repos.map! do |vr|
      osa_parsed = JSON::parse(vr[1]) rescue []
      [vr[0], osa_parsed.map {|s| s.to_i}]
    end

    # create a query WHERE subclause string for each visible repo
    # add a check for set restrictions if defined for that repo
    query_strings = visible_repos.map do |vr|
      # no set restrictions: add all the repos objects to our query
      if vr[1].length == 0
        "(repo_id = #{vr[0]})"

      # set restrictions defined: add only objects in repo that meet set restrictions
      else
        "(level_id IN (#{vr[1].join(', ')}) AND repo_id = #{vr[0]})"
      end
    end

    # No repository is exposed via OAI at all, so nothing can match.
    return dataset.filter(Sequel.lit('1 = 0')) if query_strings.empty?

    dataset.filter(Sequel.lit(query_strings.join(" OR ")))
  end

  def add_visibility_restrictions(dataset)
    apply_repository_restrictions(dataset).filter(:publish => 1, :suppressed => 0)
  end

  def add_unavailability_restrictions(dataset)
    apply_repository_restrictions(dataset)
      .filter(Sequel.|(Sequel.~(:publish => 1),
                       {:publish => nil},
                       {:suppressed => 1}))
  end

  def hidden_from_harvesters?(obj)
    obj[:publish] != 1 || obj[:suppressed] == 1
  end

  # Don't show deletes for repositories that aren't published.
  def restrict_tombstones_to_published_repositories(dataset)
    unpublished_repos = Repository.exclude(:publish => 1).select(:id).map {|row| row[:id]}

    result = dataset

    unpublished_repos.each do |repo_id|
      result = result.exclude(Sequel.like(:uri, JSONModel(:repository).uri_for(repo_id) + '/%'))
    end

    result
  end

  def options_for_type(metadata_prefix)
    ArchivesSpaceOAIRepository.available_record_types.fetch(metadata_prefix) { raise OAI::FormatException.new }
  end

  def build_set_description(text)
    result = Nokogiri::XML::Builder.new do |xml|
      xml.setDescription do
        xml['oai_dc'].dc('xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                         'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                         'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                         'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd') do

          xml['oai_dc'].description(text)
        end
      end
    end

    result.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::NO_DECLARATION)
  end

  def produce_next_record_set(resumption_token, options)
    matched_records = []
    depleted_types = []

    metadata_prefix = resumption_token.format || options.fetch(:metadata_prefix)
    set = resumption_token.set || options.fetch(:set, nil)

    format_options = options_for_type(metadata_prefix)

    resumption_token.remaining_types.each do |record_type_name, last_id|
      record_type = format_options.record_types.find {|type| type.to_s == record_type_name} or next
      limit = format_options.page_size - matched_records.length

      # Request one extra record (limit + 1) to determine whether we've hit
      # the end of the stream or not
      matches = add_visibility_restrictions(record_type.any_repo)
                  .where { id > last_id }
                  .order(:id)
                  .limit(limit + 1)

      from_timestamp = resumption_token.from || options.fetch(:from, nil)
      until_timestamp = resumption_token.until || options.fetch(:until, nil)
      matches = apply_time_restrictions(matches, from_timestamp, until_timestamp)

      matches = apply_set_restrictions(matches, set, record_type)

      if matches.count <= limit
        # No more records of this type
        depleted_types << record_type_name
      else
        # We haven't hit the end yet
      end

      matches = matches.take(limit)

      matches.zip(fetch_jsonmodels(record_type, matches)).each do |obj, json|
        matched_records << if json["has_unpublished_ancestor"]
                             OAIHiddenRecordDeletion.new(obj)
                           else
                             ArchivesSpaceOAIRecord.new(obj, json)
                           end
      end
    end

    resumption_token
      .update_depleted(depleted_types)
      .set_last_seen(matched_records.last)

    unless resumption_token.any_records_left?
      # We've produced all records.  Move on to the deletes, or finish up if there
      # aren't any (in which case no resumption token is needed).
      return matched_records unless start_next_phase!(resumption_token, options)
    end

    OAI::Provider::PartialResult.new(matched_records, resumption_token)
  end

  # Dispatch to whichever phase of the harvest the token says we're in.
  def produce_next_set(resumption_token, options)
    case resumption_token.state
    when ArchivesSpaceResumptionToken::PRODUCING_RECORDS_STATE
      produce_next_record_set(resumption_token, options)
    when ArchivesSpaceResumptionToken::PRODUCING_DELETES_STATE
      produce_next_delete_set(resumption_token, options)
    when ArchivesSpaceResumptionToken::PRODUCING_HIDDEN_STATE
      produce_next_hidden_set(resumption_token, options)
    else
      raise OAI::ResumptionTokenException.new
    end
  end

  # Advance the token to the next phase that actually has something to produce.
  # Returns false when the harvest is finished.
  def start_next_phase!(resumption_token, options)
    case resumption_token.state
    when ArchivesSpaceResumptionToken::PRODUCING_RECORDS_STATE
      if have_deletes?(resumption_token, options)
        resumption_token.start_deletes!
        true
      else
        start_hidden_phase!(resumption_token, options)
      end
    when ArchivesSpaceResumptionToken::PRODUCING_DELETES_STATE
      start_hidden_phase!(resumption_token, options)
    else
      false
    end
  end

  # Look ahead a little to see whether we have some deletes to serve out.
  # Allows us to avoid serving out a resumptionToken that would actually be
  # fruitless.
  def have_deletes?(resumption_token, options)
    !build_delete_ds(resumption_token, options).empty?
  end

  # As with have_deletes?, look ahead so we don't hand out a resumption token for
  # a phase that would turn out to be empty.  Returns true if the hidden-record
  # phase was started.
  def start_hidden_phase!(resumption_token, options)
    format_options = options_for_type(resumption_token.format || options.fetch(:metadata_prefix))

    have_hidden = format_options.record_types.any? {|record_type|
      !build_hidden_ds(record_type, resumption_token, options).empty?
    }

    return false unless have_hidden

    resumption_token.start_hidden!(format_options.record_types)

    true
  end

  # ANW-1301: records that still exist but are no longer available to harvesters,
  # because they've been suppressed or unpublished.  Their system_mtime is when
  # that happened, so the usual from/until range picks them up.
  def build_hidden_ds(record_type, resumption_token, options)
    set = resumption_token.set || options.fetch(:set, nil)
    from_timestamp = resumption_token.from || options.fetch(:from, nil)
    until_timestamp = resumption_token.until || options.fetch(:until, nil)

    dataset = add_unavailability_restrictions(record_type.any_repo)
    dataset = apply_time_restrictions(dataset, from_timestamp, until_timestamp)

    apply_set_restrictions(dataset, set, record_type)
  end

  def build_delete_ds(resumption_token, options)
    metadata_prefix = resumption_token.format || options.fetch(:metadata_prefix)
    set = resumption_token.set || options.fetch(:set, nil)

    format_options = options_for_type(metadata_prefix)

    # Get a dataset that will pull back all tombstones for the record types that
    # this metadata type supports.
    matching_tombstones = format_options.record_types.map {|record_type|
      tombstone_ds = ArchivesSpaceOAIRepository.delete_lookups[record_type]
      if tombstone_ds
        restrict_tombstones_to_published_repositories(tombstone_ds)
      end
    }.compact.reduce {|deletes, tombstone_ds|
      deletes.union(tombstone_ds)
    }

    # If our original query had a date range, limit the tombstones by date too
    from_timestamp = resumption_token.from || options.fetch(:from, nil)
    until_timestamp = resumption_token.until || options.fetch(:until, nil)

    apply_time_restrictions(matching_tombstones, from_timestamp, until_timestamp, :timestamp)
  end

  def produce_next_delete_set(resumption_token, options)
    matching_tombstones = build_delete_ds(resumption_token, options)

    last_id = resumption_token.last_delete_id

    limit = DELETES_PER_PAGE

    # Request one extra record (limit + 1) to determine whether we've hit
    # the end of the stream or not
    matches = matching_tombstones
                .where { id > last_id }
                .order(:id)
                .limit(limit + 1)

    finished = (matches.count <= limit)

    matched_records = matches.take(limit).map {|tombstone| OAIDeletion.new(tombstone)}

    resumption_token.last_delete_id = matched_records.last.tombstone_id unless matched_records.empty?

    if finished
      # Out of tombstones.  Move on to the records that have been hidden rather
      # than deleted, or finish up if there aren't any.
      return matched_records unless start_next_phase!(resumption_token, options)
    end

    OAI::Provider::PartialResult.new(matched_records, resumption_token)
  end

  # ANW-1301: the final phase of a harvest.  Serves out a deletion for every
  # record that has been suppressed or unpublished within the requested date
  # range, so that harvesters know to withdraw their copies.
  #
  # These are paged at DELETES_PER_PAGE rather than the format's page size: they
  # produce nothing but a header, and oai_ead's page size of one would otherwise
  # mean a request per hidden resource.
  def produce_next_hidden_set(resumption_token, options)
    matched_records = []
    depleted_types = []

    metadata_prefix = resumption_token.format || options.fetch(:metadata_prefix)
    format_options = options_for_type(metadata_prefix)

    resumption_token.hidden_types.each do |record_type_name, last_id|
      record_type = format_options.record_types.find {|type| type.to_s == record_type_name}

      if record_type.nil?
        depleted_types << record_type_name
        next
      end

      limit = DELETES_PER_PAGE - matched_records.length

      # This page is already full
      next if limit <= 0

      # Request one extra record (limit + 1) to determine whether we've hit
      # the end of the stream or not
      matches = build_hidden_ds(record_type, resumption_token, options)
                  .where { id > last_id }
                  .order(:id)
                  .limit(limit + 1)

      if matches.count <= limit
        # No more hidden records of this type
        depleted_types << record_type_name
      end

      matches.take(limit).each do |obj|
        matched_records << OAIHiddenRecordDeletion.new(obj)
      end
    end

    resumption_token
      .update_hidden_depleted(depleted_types)
      .set_last_hidden_seen(matched_records.last)

    # This is the last phase, so once it's depleted the harvest is over.
    return matched_records unless resumption_token.any_hidden_left?

    OAI::Provider::PartialResult.new(matched_records, resumption_token)
  end


  def apply_time_restrictions(dataset, from_timestamp, until_timestamp, time_column = :system_mtime)
    from_time = parse_time(from_timestamp)
    until_time = parse_time(until_timestamp)

    if from_time
      dataset = dataset.filter(Sequel.lit("#{time_column} >= ?", from_time))
    end

    if until_time
      dataset = dataset.filter(Sequel.lit("#{time_column} <= ?", until_time))
    end

    dataset
  end

  def parse_time(s_or_time)
    if s_or_time.nil?
      nil
    elsif s_or_time.is_a?(Time)
      return s_or_time
    else
      parsed = Time.parse(s_or_time)

      if parsed.utc_offset != 0
        # We want our timestamp as UTC!
        offset = parsed.utc_offset

        parsed.utc + offset
      else
        parsed
      end
    end
  end

  def apply_set_restrictions(dataset, set, model)
    if set.nil?
      # No further restrictions
      return dataset
    end

    set = set.to_s

    # If the set name corresponds to a known record level, use that as our limit
    available_levels = BackendEnumSource.values_for("archival_record_level")

    if available_levels.include?(set)
      level_id = BackendEnumSource.id_for_value("archival_record_level", set)

      return dataset.filter(:level_id => level_id)
    end

    # ANW-674
    # Otherwise, look for manually defined sets in the OAIConfig table
    get_oai_config_values

    if @repo_set_codes.any? && set == @repo_set_name
      dataset = dataset.filter(:repo_id => Repository.filter(:repo_code => @repo_set_codes).select(:id))

    # We work off the SHA1 of the sponsor here because the sponsor is stored in
    # a text column, and since we don't know how long people's sponsor text
    # might be in the wild, it seemed risky to change the column type.
    elsif @sponsor_set_names.any? && set == @sponsor_set_name
      sponsor_hashes = @sponsor_set_names.map {|sponsor| Digest::SHA1.hexdigest(sponsor)}

      if model == Resource
        dataset = dataset.filter(:finding_aid_sponsor_sha1 => sponsor_hashes)
      else
        dataset = dataset.filter(:root_record_id => Resource.filter(:finding_aid_sponsor_sha1 => sponsor_hashes).select(:id))
      end
    end

    dataset
  end

  def fetch_jsonmodels(record_type, objs)
    result = []

    objs.group_by(&:repo_id).each do |repo_id, subset|
      RequestContext.open(:repo_id => repo_id) do
        jsons = record_type.sequel_to_jsonmodel(subset)

        # Resolve ancestors since the RecordInheritance code expects them to be there
        # and merge in the ancestor values according to the configuration and resolve everything else we need.
        resolved = RecordInheritance.merge(URIResolver.resolve_references(jsons, RESOLVE))

        result.concat(resolved.map {|json| JSONModel::JSONModel(json.fetch('jsonmodel_type').intern).from_hash(json, true, :trusted)})
      end
    end

    result
  end
end
