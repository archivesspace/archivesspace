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

  RESOLVE = ['repository', 'subjects', 'linked_agents', 'digital_object', 'top_container', 'ancestors', 'linked_agents', 'resource']


  def earliest
    Time.at(0).utc
  end

  def latest
    Time.now.utc
  end

  def sets
    available_levels = BackendEnumSource.values_for("archival_record_level")

    config_sets = []

    if AppConfig.has_key?(:oai_sets)
      config_sets = AppConfig[:oai_sets].map {|set_name, values|
        unless available_levels.include?(set_name)
          set_properties = {:name => set_name, :spec => set_name}

          if (description = values.fetch(:description, nil))
            set_properties[:description] = build_set_description(description)
          end

          OAI::Set.new(set_properties)
        end
      }.compact
    end

    level_sets = available_levels.map {|level|
      OAI::Set.new(:name => level, :spec => level)
    }

    config_sets + level_sets
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

    RequestContext.open(:repo_id => repo_id) do
      obj = add_visibility_restrictions(model.filter(:id => parsed_ref[:id])).first

      raise OAI::IdException.new unless obj

      ArchivesSpaceOAIRecord.new(obj, fetch_jsonmodels(model, [obj])[0])
    end
  end

  def find(selector, options = {})
    if selector.is_a?(String)
      return fetch_single_record(selector, options)
    end

    resumption_token = if options.has_key?(:resumption_token)
                         ArchivesSpaceResumptionToken.parse(options.fetch(:resumption_token), ArchivesSpaceOAIRepository.available_record_types)
                       else
                         ArchivesSpaceResumptionToken.new(options, ArchivesSpaceOAIRepository.available_record_types)
                       end

    if resumption_token.state == ArchivesSpaceResumptionToken::PRODUCING_RECORDS_STATE
      records = produce_next_record_set(resumption_token, options)

      if records.is_a?(OAI::Provider::PartialResult) && records.records.empty?
        # We didn't match any records, but there might still be some deletes of interest...
        produce_next_delete_set(records.token, options)
      else
        records
      end
    elsif resumption_token.state == ArchivesSpaceResumptionToken::PRODUCING_DELETES_STATE
      produce_next_delete_set(resumption_token, options)
    else
      raise OAI::ResumptionTokenException.new
    end
  end


  private

  def add_visibility_restrictions(dataset)
    unpublished_repos = Repository.exclude(:publish => 1).select(:id).map {|row| row[:id]}

    dataset.exclude(:repo_id => unpublished_repos).filter(:publish => 1, :suppressed => 0)
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
        matched_records << ArchivesSpaceOAIRecord.new(obj, json)
      end
    end

    resumption_token
      .update_depleted(depleted_types)
      .set_last_seen(matched_records.last)

    unless resumption_token.any_records_left?
      # We've produced all records.  Start producing deletes.
      if have_deletes?(resumption_token, options)
        resumption_token.start_deletes!
      else
        # finished with no resumption token needed
        return matched_records
      end
    end

    OAI::Provider::PartialResult.new(matched_records, resumption_token)
  end

  # Look ahead a little to see whether we have some deletes to serve out.
  # Allows us to avoid serving out a resumptionToken that would actually be
  # fruitless.
  def have_deletes?(resumption_token, options)
    !build_delete_ds(resumption_token, options).empty?
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

    if finished
      matched_records
    else
      # If there are still records to produce, keep going.
      resumption_token.last_delete_id = matched_records.last.tombstone_id
      OAI::Provider::PartialResult.new(matched_records, resumption_token)
    end
  end


  def apply_time_restrictions(dataset, from_timestamp, until_timestamp, time_column = :system_mtime)
    from_time = parse_time(from_timestamp)
    until_time = parse_time(until_timestamp)

    if from_time
      dataset = dataset.filter("#{time_column} >= ?", from_time)
    end

    if until_time
      dataset = dataset.filter("#{time_column} <= ?", until_time)
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

    # Otherwise, look for manually defined sets from the config file.
    if AppConfig.has_key?(:oai_sets)
      set_definition = AppConfig[:oai_sets].fetch(set)

      if set_definition[:repo_codes]
        dataset = dataset.filter(:repo_id => Repository.filter(:repo_code => set_definition[:repo_codes]).select(:id))
      end

      # We work off the SHA1 of the sponsor here because Derby doesn't make it
      # easy to compare CLOBs with strings without DB-specific stuff.  And since
      # we don't know how long people's sponsor text might be in the wild, it
      # seemed risky to change the column type.
      if set_definition[:sponsors]
        sponsor_hashes = set_definition[:sponsors].map {|sponsor| Digest::SHA1.hexdigest(sponsor)}

        if model == Resource
          dataset = dataset.filter(:finding_aid_sponsor_sha1 => sponsor_hashes)
        else
          dataset = dataset.filter(:root_record_id => Resource.filter(:finding_aid_sponsor_sha1 => sponsor_hashes).select(:id))
        end
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
        jsons = URIResolver.resolve_references(jsons, ['ancestors'])

        # Now merge in the ancestor values according to the configuration and resolve everything else we need.
        jsons = RecordInheritance.merge(jsons)
        resolved = URIResolver.resolve_references(jsons, RESOLVE)

        result.concat(resolved.map {|json| JSONModel::JSONModel(json.fetch('jsonmodel_type').intern).from_hash(json, true, :trusted)})
      end
    end

    result
  end
end
