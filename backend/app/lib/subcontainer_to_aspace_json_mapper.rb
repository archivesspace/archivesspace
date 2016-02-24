# Take our record containing managed containers and generate corresponding
# ArchivesSpace container records.
class SubContainerToAspaceJsonMapper

  include JSONModel

  def initialize(instance_json, instance_obj)
    @instance_json = instance_json
    @instance_obj = instance_obj
  end


  def to_hash
    result = Hash[JSONModel(:container).schema['properties'].map {|property, _| [property, self.send(property.intern)]}]

    result
  end

  def lock_version
        top_container.lock_version
  end

  def type_1
    top_container.type || 'box'
  end


  def indicator_1
    top_container.indicator
  end


  def barcode_1
    top_container.barcode
  end


  def container_locations
    relationship = TopContainer.find_relationship(:top_container_housed_at)

    relationship.find_by_participant(top_container).map {|container_location|
      properties = container_location.values.merge('ref' => Location.uri_for(:location, container_location[:location_id]))
      properties[:jsonmodel_type] ||= "container_location"
      properties[:start_date] = properties[:start_date].strftime('%Y-%m-%d') if properties[:start_date]
      properties[:end_date] = properties[:end_date].strftime('%Y-%m-%d') if properties[:end_date]

      JSONModel(:container_location).from_hash(properties, true, true).to_hash(:trusted)
    }
  end


  def method_missing(method, *args)
    nil
  end


  private

  def container_profile
    @container_profile ||= top_container.related_records(:top_container_profile)
  end

  def top_container
    @top_container ||= sub_container.related_records(:top_container_link)
  end

  def sub_container
    @sub_container ||= @instance_obj.sub_container.first
  end

  def type_2
    sub_container.type_2
  end

  def indicator_2
    sub_container.indicator_2
  end

  def type_3
    sub_container.type_3
  end

  def indicator_3
    sub_container.indicator_3
  end


end
