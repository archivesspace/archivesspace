class AspaceJsonToManagedContainerMapper

  include JSONModel

  def initialize(json, new_record)
    @json = json
    @new_record = new_record
    @new_top_containers = []
  end


  class LocationMismatchException < ValidationException
  end


  class ContainerProfileMismatchException < ValidationException
  end


  def call
    @json['instances'].each do |instance|

      # Make sure we're dealing with a hash, not a JSONModel
      instance = instance.is_a?(JSONModelType) ? instance.to_hash(:raw) : instance

      if instance['sub_container'] || instance['digital_object']
        # Just need to make sure there are no conflicting ArchivesSpace containers
        # instance.delete('container')
        next
      end

      if !instance['container']
        # This instance must be empty.  No sub container, digital object or aspace container!
        Log.warn("Empty instance found.  Skipped!")
        next
      end


      top_container = get_or_create_top_container(instance)

      begin
        exception = nil 
        ensure_harmonious_values(top_container, instance['container'])
      rescue LocationMismatchException => e
        if @json.is_a?(JSONModel(:accession))
          # We handle this case specially because the AT migrator sends multiple
          # locations attached to an accession as containers with identical
          # indicator_1 values but differing locations.
          #
          # For an accession, match on indicator_1 but mismatch on location
          # means we're really talking about different Top Containers.

          container = instance['container']

          top_container = create_top_container({'indicator' => get_default_indicator(container['indicator_1']),
                                               'type' => container['type_1'], 
                                               'container_locations' => container['container_locations']})
        else
          # let's store that something bad happened, but we need to make the
          # rest of the subcontainers so that the instance is linked to
          # something... 
          exception = e
        end
      end

      subcontainer = {
        'top_container' => {'ref' => top_container.uri},
      }
      instance['container']['jsonmodel_type'] ||= 'container'
      [2, 3].each do |level|
        # ArchivesSpace containers allow type_2/3 to be set without
        # indicator_2/3.  Provide a default if it's missing.
        if instance['container']["type_#{level}"]
          subcontainer["type_#{level}"] = instance['container']["type_#{level}"]
          subcontainer["indicator_#{level}"] = instance['container']["indicator_#{level}"] || get_default_indicator
        end
      end

      if instance['container']["type_3"] && !instance['container']["type_2"]
        # Promote type_3 to type_2 to stop validation blowing up
        subcontainer["type_2"] = instance['container']["type_3"]
        subcontainer["indicator_2"] = instance['container']["indicator_3"] || get_default_indicator

        subcontainer["type_3"] = nil
        subcontainer["indicator_3"] = nil
      end


      instance['sub_container'] = subcontainer
      raise exception if exception
      # No need for the original value now.
      instance.delete('container')
    end
  end


  protected

  def try_matching_barcode(container)
    # If we have a barcode, attempt to locate an existing top container but create one if needed
    barcode = container['barcode_1']

    if barcode
      if (top_container = TopContainer.for_barcode(barcode))
        top_container
      else
        indicator = container['indicator_1'] || get_default_indicator
        create_top_container({'barcode' => barcode,
                              'indicator' => indicator,
                              'type' => container['type_1'], 
                              'container_locations' => container['container_locations']})
      end
    else
      nil
    end
  end


  def try_matching_indicator_within_record(container)
    indicator = container['indicator_1']
    type = container["type_1"] 

    # Record is being created so nothing to search for yet.
    return nil if !@json['uri']

    model = if @json.is_a?(JSONModel(:archival_object))
               ArchivalObject
             elsif @json.is_a?(JSONModel(:resource))
               Resource
             elsif @json.is_a?(JSONModel(:accession))
               Accession
             else
               nil
             end

    return nil if !model

    id = @json.class.id_for(@json['uri'])
    return nil if id.to_i == 0 # it's a new record and we have nothing to create. 

    join_column = model.association_reflection(:instance)[:key]
    find_top_container_by_instances(Instance.filter(join_column => id).select(:id), indicator, type)
  
  end


  def try_matching_indicator_within_collection(container)
    indicator = container['indicator_1']

    type_type_id = Enumeration.filter( :name => 'container_type' ).get(:id) 
    type_id = EnumerationValue.filter( :enumeration_id => type_type_id, :value => container["type_1"] ).get(:id) 

    return nil if !type_id

    resource_uri = @json['resource'] && @json['resource']['ref']
    return nil if !resource_uri

    resource_id = JSONModel(:resource).id_for(resource_uri)

    matching_top_containers_by_instance =
      TopContainer.linked_instance_ds.
      join(:archival_object, :id => :instance__archival_object_id).
      filter(:instance__resource_id => resource_id).
      filter(:top_container__indicator => indicator).
      filter(:top_container__type_id => type_id).
      select_all(:top_container)

    matching_top_containers_by_ao =
      TopContainer.linked_instance_ds.
      join(:archival_object, :id => :instance__archival_object_id).
      filter(:archival_object__root_record_id => resource_id).
      filter(:top_container__indicator => indicator).
      filter(:top_container__type_id => type_id).
      select_all(:top_container)

    matching_top_containers_by_instance.first || matching_top_containers_by_ao.first
  end

  def ensure_harmonious_values(top_container, aspace_container)
    properties = {:indicator => 'indicator_1', :barcode => 'barcode_1', :type_id => 'type_id'}

    # we jam the type id into the hash here...uck.
    type = EnumerationValue.filter(  :id => top_container[:type_id] ).get(:id) 
    aspace_container["type_id"] = type

    properties.each do |top_container_property, aspace_property|
      if aspace_container[aspace_property] && top_container[top_container_property] != aspace_container[aspace_property]

        raise ValidationException.new(:errors => {aspace_property => ["Mismatch when mapping between #{top_container_property} and #{aspace_property}"]},
                                      :object_context => {
                                        :top_container => top_container,
                                        :aspace_container => aspace_container
                                      })
      end
    end


    aspace_locations = Array(aspace_container['container_locations']).map {|container_location| container_location['ref']}
    top_container_locations = top_container.related_records(:top_container_housed_at).map(&:uri)

    if aspace_locations.empty? || ((top_container_locations - aspace_locations).empty? && (aspace_locations - top_container_locations).empty?)
    # All OK!
    elsif top_container_locations.empty?
      # We'll just take the incoming location if we don't have any better ideas
      top_container.refresh
      json = TopContainer.to_jsonmodel(top_container, :skip_restrictions => true)
      json['container_locations'] = aspace_container['container_locations']
      top_container.update_from_json(json)
      top_container.refresh
    else
      raise LocationMismatchException.new(:errors => {'container_locations' => ["Locations in ArchivesSpace container don't match locations in existing top container"]},
                                          :object_context => {
                                            :top_container => top_container,
                                            :aspace_container => aspace_container,
                                            :top_container_locations => top_container_locations,
                                            :aspace_locations => aspace_locations,
                                          })
    end


    # check the container profile if a profile 'container_profile_key' was provided
    incoming_container_profile = find_container_profile(aspace_container)
    if incoming_container_profile
      top_container_profile = top_container.related_records(:top_container_profile)
      if !top_container_profile
        # no profile? let's set the incoming profile on the top container
        TopContainer.find_relationship(:top_container_profile).relate(top_container,
                                                                      incoming_container_profile,
                                                                      {
                                                                        :aspace_relationship_position => 0,
                                                                        :system_mtime => Time.now,
                                                                        :user_mtime => Time.now
                                                                      })
      elsif incoming_container_profile.id != top_container_profile.id
        # mismatch with existing profile
        raise ContainerProfileMismatchException.new(:errors => {'container_profile' => ["Container Profile in ArchivesSpace container (#{aspace_container['container_profile_key']}) doesn't match profile in existing top container (#{top_container_profile.name})"]},
                                                    :object_context => {
                                                      :top_container => top_container,
                                                      :aspace_container => aspace_container,
                                                      :incoming_container_profile => incoming_container_profile,
                                                      :top_container_profile => top_container_profile,
                                                    })
      else
        # matchy match!
      end
    end
  end



  private


  def new_record?
    @new_record
  end

  def create_extents_from_container_extents(instance)
    container = instance['container']
    extent= nil 
    if ( container["container_extent"] && container["container_extent_type"] )
      extent = JSONModel(:extent).from_hash({:number => container["container_extent"], 
                :extent_type => container["container_extent_type"],
                :portion => "whole"
                })
    end
    extent 
  end

  def get_or_create_top_container(instance)
    container = instance['container']

    if container['barcode_1'] && container['barcode_1'].strip == ""
      # Seriously?  Yeesh.  Bad barcode!  No biscuit!
      container['barcode_1'] = nil
    end

    if (result = try_matching_barcode(container))
      return result
    else
      indicator = container['indicator_1']
      type = container["type_1"]

      match = try_matching_indicator_and_type(container, indicator, type)

      if match
        return match
      end
    end
   
    
    Log.info("Creating a new Top Container for a container with no barcode, type: #{ container["type_1"] }, indicator #{container['indicator_1'] || get_default_indicator}")
    

    
    
    create_top_container( {'indicator' => (container['indicator_1'] || get_default_indicator),
                         'type' => container["type_1"],  
                         'container_locations' => container['container_locations']})
  end


  def create_top_container(values)
    created = TopContainer.create_from_json(JSONModel(:top_container).from_hash(values))
    @new_top_containers << created
    Log.info("Top Container created : #{created.inspect}")
    created
  end


  def try_matching_indicator_and_type(container, indicator, type)
    return nil if !indicator
    
    type_type_id = Enumeration.filter( :name => 'container_type' ).get(:id) 
    type_id= EnumerationValue.filter( :enumeration_id => type_type_id, :value => container["type_1"] ) 
    return nil if !type_id

    # If we've created a matching top container for this record already, use that.
    @new_top_containers.each do |top_container|
      if top_container.indicator == indicator && top_container.type_id == type_id
        return top_container
      end
    end

    if @json.is_a?(JSONModel(:accession)) || @json.is_a?(JSONModel(:resource))
      try_matching_indicator_within_record(container)
    else
      try_matching_indicator_within_collection(container)
    end
  end


  def get_default_indicator(prefix = 'data_value_missing')
    "#{prefix}_#{SecureRandom.hex}"
  end


  def find_top_container_within_subtree(top_record, indicator)
    ao_ids = [top_record.id]

    # Find the IDs of all records under this point
    new_ao_ids = [top_record.id]

    while true
      new_ao_ids = ArchivalObject.filter(:parent_id => new_ao_ids).select(:id).map(&:id)

      if new_ao_ids.empty?
        break
      else
        ao_ids += new_ao_ids
      end
    end


    # Find all linked instances
    instance_ds = Instance.filter(:archival_object_id => ao_ids).select(:id)

    find_top_container_by_instances(instance_ds, indicator)
  end


  def find_top_container_by_instances(instance_ds, indicator, type)
    # All subcontainers linked to our instances
    subcontainer_ds = SubContainer.filter(:instance_id => instance_ds)

    relationship_model = SubContainer.find_relationship(:top_container_link)
    top_containers_for_subcontainers = relationship_model.filter(:sub_container_id => subcontainer_ds.select(:id)).select(:top_container_id)
    
    type_type_id = Enumeration.filter( :name => 'container_type' ).get(:id) 
    type_id = EnumerationValue.filter( :enumeration_id => type_type_id, :value => type ).get(:id)

    TopContainer[:indicator => indicator, :type_id => type_id, 
                 :id => top_containers_for_subcontainers]
  end


  def find_container_profile(container)
    key = container['container_profile_key']
    if key
      ContainerProfile.filter(:name => key).or(:url => key).first
    end
  end

end
