class LocationHoldingsReport < AbstractReport

  register_report({
                    :params => [["locations", "LocationList", "The locations of interest"]]
                  })

  include JSONModel

  attr_reader :building, :repository_uri, :start_location, :end_location

  def initialize(params, job, db)
    super

    if ASUtils.present?(params['building'])
      @building = params['building']
    elsif ASUtils.present?(params['repository_uri'])
      @repository_uri = params['repository_uri']

      RequestContext.open(:repo_id => JSONModel(:repository).id_for(@repository_uri)) do
        unless current_user.can?(:view_repository)
          raise AccessDeniedException.new("User does not have access to view the requested repository")
        end
      end
    else
      @start_location = Location.get_or_die(JSONModel(:location).id_for(params['location_start']['ref']))

      if ASUtils.present?(params['location_end'])
        @end_location = Location.get_or_die(JSONModel(:location).id_for(params['location_end']['ref']))
      end
    end
  end

  def headers
    [
      'building', 'floor_and_room', 'location_in_room',
      'location_url', 'location_profile', 'location_barcode',
      'resource_or_accession_id', 'resource_or_accession_title',
      'top_container_indicator', 'top_container_barcode', 'container_profile',
      'ils_item_id', 'ils_holding_id', 'repository'
    ]
  end

  def processor
    {
      'floor_and_room' => proc {|row| floor_and_room(row)},
      'location_in_room' => proc {|row| location_in_room(row)},
      'location_url' => proc {|row| location_url(row)},
    }
  end

  def query
    dataset = if building
                building_query
              elsif repository_uri
                repository_query
              elsif start_location && end_location
                range_query
              else
                single_query
              end

    # Join location to top containers, repository and (optionally) location and container profiles
    dataset = dataset
                .left_outer_join(:location_profile_rlshp, :location_id => :location__id)
                .left_outer_join(:location_profile, :id => :location_profile_rlshp__location_profile_id)
                .join(:top_container_housed_at_rlshp,
                      :location_id => :location__id,
                      :top_container_housed_at_rlshp__status => 'current')
                .join(:top_container, :id => :top_container_housed_at_rlshp__top_container_id)
                .join(:repository, :id => :top_container__repo_id)
                .left_outer_join(:top_container_profile_rlshp, :top_container_id => :top_container_housed_at_rlshp__top_container_id)
                .left_outer_join(:container_profile, :id => :top_container_profile_rlshp__container_profile_id)

    # A top container can be linked (via subcontainer) to an instance attached
    # to an archival object, resource or accession.  We'd like to report on the
    # ultimate collection of that linkage--the accession or resource tree that
    # the top container is linked into.
    #
    # So, here comes more joins...
    dataset = dataset
                .left_outer_join(:top_container_link_rlshp, :top_container_id => :top_container__id)
                .left_outer_join(:sub_container, :id => :top_container_link_rlshp__sub_container_id)
                .left_outer_join(:instance, :id => :sub_container__instance_id)
                .left_outer_join(:archival_object, :id => :instance__archival_object_id)
                .left_outer_join(:resource, :id => :instance__resource_id)
                .left_outer_join(:accession, :id => :instance__accession_id)
                .left_outer_join(:resource___resource_via_ao, :id => :archival_object__root_record_id)

    # Used so we can combine adjacent rows for accession/resources linkages
    # (i.e. one top container linked to multiple collections)
    dataset = dataset.order(:top_container_id)

    dataset = dataset.select(Sequel.as(:location__building, :building),
                             Sequel.as(:location__floor, :floor),
                             Sequel.as(:location__room, :room),
                             Sequel.as(:location__area, :area),
                             Sequel.as(:location__id, :location_id),

                             Sequel.as(:location__coordinate_1_label, :coordinate_1_label),
                             Sequel.as(:location__coordinate_1_indicator, :coordinate_1_indicator),
                             Sequel.as(:location__coordinate_2_label, :coordinate_2_label),
                             Sequel.as(:location__coordinate_2_indicator, :coordinate_2_indicator),
                             Sequel.as(:location__coordinate_3_label, :coordinate_3_label),
                             Sequel.as(:location__coordinate_3_indicator, :coordinate_3_indicator),

                             Sequel.as(:location_profile__name, :location_profile),
                             Sequel.as(:location__barcode, :location_barcode),
                             Sequel.as(:top_container__indicator, :top_container_indicator),
                             Sequel.as(:top_container__barcode, :top_container_barcode),
                             Sequel.as(:container_profile__name, :container_profile),
                             Sequel.as(:top_container__id, :top_container_id),
                             Sequel.as(:top_container__ils_item_id, :ils_item_id),
                             Sequel.as(:top_container__ils_holding_id, :ils_holding_id),
                             Sequel.as(:repository__name, :repository),

                             Sequel.as(:resource__title, :resource_title),
                             Sequel.as(:resource_via_ao__title, :resource_via_ao_title),
                             Sequel.as(:accession__title, :accession_title),

                             Sequel.as(:resource__identifier, :resource_identifier),
                             Sequel.as(:resource_via_ao__identifier, :resource_via_ao_identifier),
                             Sequel.as(:accession__identifier, :accession_identifier))

    dataset
  end

  def building_query
    db[:location].filter(:location__building => building)
  end

  def repository_query
    repo_id = JSONModel.parse_reference(repository_uri)[:id]

    location_ids = db[:location]
                     .join(:top_container_housed_at_rlshp, :location_id => :location__id)
                     .join(:top_container, :top_container__id => :top_container_housed_at_rlshp__top_container_id)
                     .filter(:top_container__repo_id => repo_id)
                     .select(:location__id)

    ds = db[:location].filter(:location__id => location_ids)

    # We add a filter at this point to only show holdings for the current
    # repository.  This works because we know our dataset will be joined with
    # the top_container table in our `query` method, and Sequel doesn't mind if
    # we add filters for columns that haven't been joined in yet.
    #
    ds.filter(:top_container__repo_id => repo_id)
  end

  def single_query
    db[:location].filter(:location__id => start_location.id)
  end

  def range_query
    # Find the most specific mismatch between the two locations: building -> floor -> room -> area -> c1 -> c2 -> c3
    properties_to_compare = [:building, :floor, :room, :area]

    [1, 2, 3].each do |coordinate|
      label = "coordinate_#{coordinate}_label"
      if !start_location[label].nil? && start_location[label] == end_location[label]
        properties_to_compare << "coordinate_#{coordinate}_indicator".intern
      else
        break
      end
    end

    matching_properties = []
    determinant_property = nil

    properties_to_compare.each do |property|

      if start_location[property] && end_location[property]

        if start_location[property] == end_location[property]
          # If both locations have the same value for this property, we'll skip it for the purposes of our range calculation
          matching_properties << property
        else
          # But if they have different values, that's what we'll use for the basis of our range
          determinant_property = property
          break
        end

      elsif !start_location[property] && !end_location[property]
        # If neither location has a value for this property, skip it
        next

      else
        # If we hit a property that only one location has a value for, we can't use it for a range calculation
        break
      end

    end

    if matching_properties.empty? && determinant_property.nil?
      # an empty dataset
      return db[:location].where { 1 == 0 }
    end

    dataset = db[:location]

    matching_properties.each do |property|
      dataset = dataset.filter(property => start_location[property])
    end

    if determinant_property
      range_start, range_end = [start_location[determinant_property], end_location[determinant_property]].sort
      dataset = dataset
                  .filter("#{determinant_property} >= ?", range_start)
                  .filter("#{determinant_property} <= ?", range_end)
    end

    dataset
  end

  def each
    collection_identifier_fields = [:resource_identifier, :resource_via_ao_identifier, :accession_identifier]
    collection_title_fields = [:resource_title, :resource_via_ao_title, :accession_title]

    dataset = query

    current_entry = nil
    enum = dataset.to_enum

    while true
      row = next_row(enum)

      if row && current_entry && current_entry[:_top_container_id] == row[:top_container_id]
        # This row can be combined with the previous entry
        collection_identifier_fields.each do |field|
          current_entry['resource_or_accession_id'] << row[field]
        end

        collection_title_fields.each do |field|
          current_entry['resource_or_accession_title'] << row[field]
        end
      else
        if current_entry
          # Yield the old value
          current_entry.delete(:_top_container_id)
          current_entry['resource_or_accession_id'] = current_entry['resource_or_accession_id'].compact.uniq.map {|s| format_identifier(s)}.join('; ')
          current_entry['resource_or_accession_title'] = current_entry['resource_or_accession_title'].compact.uniq.join('; ')
          yield current_entry
        end

        # If we hit the end of our rows, we're all done
        break unless row

        # Otherwise, start a new entry for the next row
        current_entry = Hash[headers.map { |h|
          val = (processor.has_key?(h)) ? processor[h].call(row) : row[h.intern]
          [h, val]
        }]

        current_entry['resource_or_accession_id'] = collection_identifier_fields.map {|field| row[field]}
        current_entry['resource_or_accession_title'] = collection_title_fields.map {|field| row[field]}

        # Use the top container ID to combine adjacent rows
        current_entry[:_top_container_id] = row[:top_container_id]
      end
    end
  end

  private

  def next_row(enum)
    enum.next
  rescue StopIteration
    nil
  end

  def format_identifier(s)
    if ASUtils.blank?(s)
      s
    else
      ASUtils.json_parse(s).compact.join(" -- ")
    end
  end

  def floor_and_room(row)
    [row[:floor], row[:room]].compact.join(', ')
  end

  def location_in_room(row)
    fields = [row[:area]]

    [1, 2, 3].each do |coordinate|
      if row["coordinate_#{coordinate}_label".intern]
        fields << ("%s: %s" % [row["coordinate_#{coordinate}_label".intern],
                               row["coordinate_#{coordinate}_indicator".intern]])
      end
    end

    fields.compact.join(', ')
  end

  def location_url(row)
    JSONModel(:location).uri_for(row[:location_id])
  end

end
