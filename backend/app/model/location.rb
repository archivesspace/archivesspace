class Location < Sequel::Model(:location)
  include ASModel
  corresponds_to JSONModel(:location)

  include ExternalIDs
  include AutoGenerator

  set_model_scope :global

  define_relationship(:name => :location_profile,
                      :json_property => 'location_profile',
                      :contains_references_to_types => proc {[LocationProfile]},
                      :is_array => false)

  define_relationship(:name => :owner_repo,
                      :json_property => 'owner_repo',
                      :contains_references_to_types => proc {[Repository]},
                      :is_array => false)

  one_to_many :location_function
  def_nested_record(:the_property => :functions,
                    :contains_records_of_type => :location_function,
                    :corresponding_to_association  => :location_function)


  def self.generate_title(json)
    title = ""

    title << json['building']
    title << ", #{json['floor']}" if json['floor']
    title << ", #{json['room']}" if json['room']
    title << ", #{json['area']}" if json['area']

    others = []
    others << json['barcode'] if json['barcode']
    others << json['classification'] if json['classification']
    others << "#{json['coordinate_1_label']}: #{json['coordinate_1_indicator']}" if json['coordinate_1_label']
    others << "#{json['coordinate_2_label']}: #{json['coordinate_2_indicator']}" if json['coordinate_2_label']
    others << "#{json['coordinate_3_label']}: #{json['coordinate_3_indicator']}" if json['coordinate_3_label']

    title << " [#{others.join(", ")}]"

    title
  end

  auto_generate :property => :title,
                :generator => proc {|json|
                  Location.generate_title(json)
                }



  def self.uniqify_functions(json)
    found_fns = []
    json['functions'] = json['functions'].select do |fn|
      if found_fns.include? fn['location_function_type']
        false
      else
        found_fns << fn['location_function_type']
        true
      end
    end
  end


  def self.create_from_json(json, opts = {})
    self.uniqify_functions(json)
    super
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.uniqify_functions(json)
    super
  end


  def self.create_for_batch(batch)
    locations = generate_locations_for_batch(batch)
    locations.map {|location| self.create_from_json(location)}
  end

  def self.batch_update(location)
    location[:record_uris].map do |uri|
      id = JSONModel.parse_reference(uri)[:id]
      json = Location.to_jsonmodel(id)
      json.update(location.to_hash)

      cleaned = JSONModel(:location).from_hash(json.to_hash)

      Location.get_or_die(id).update_from_json(cleaned)
    end
  end

  def self.titles_for_batch(batch)
    locations = generate_locations_for_batch(batch)
    locations.map {|location| self.generate_title(location)}
  end

  def self.generate_locations_for_batch(batch)
    indicators_1, indicators_2, indicators_3 = [batch["coordinate_1_range"], batch["coordinate_2_range"], batch["coordinate_3_range"]].
                                                  compact.
                                                  map {|data| generate_indicators(data)}

    source_location = batch.clone

    results = []

    indicators_1.each do |indicator_1|
      source_location["coordinate_1_label"] = batch["coordinate_1_range"]["label"]
      source_location["coordinate_1_indicator"] = indicator_1

      if indicators_2
        indicators_2.each do |indicator_2|
          source_location["coordinate_2_label"] = batch["coordinate_2_range"]["label"]
          source_location["coordinate_2_indicator"] = indicator_2

          if indicators_3
            indicators_3.each do |indicator_3|
              source_location["coordinate_3_label"] = batch["coordinate_3_range"]["label"]
              source_location["coordinate_3_indicator"] = indicator_3

              results.push(JSONModel(:location).from_hash(source_location))
            end
          else
            results.push(JSONModel(:location).from_hash(source_location))
          end
        end
      else
        results.push(JSONModel(:location).from_hash(source_location))
      end
    end

    results
  end

  def self.generate_indicators(opts)
    range = (opts["start"]..opts["end"]).take(AppConfig[:max_location_range].to_i)
    range.map {|i| "#{opts["prefix"]}#{i}#{opts["suffix"]}"}
  end


  def delete
    # only allow delete if the location doesn't have any relationships that should be preserved
    object_graph = self.object_graph

    # These relationships should not prevent deletion if the location is otherwise unlinked.
    ignored_relationships = [Location.find_relationship(:location_profile),
                             Location.find_relationship(:owner_repo)]

    if object_graph.models.any? {|model| model.is_relationship? && !ignored_relationships.include?(model) }
      raise ConflictException.new("Location cannot be deleted if linked")
    end

    super
  end


  def self.building_data
    buildings = {}
    all = self.exclude(building: nil).order_by(:building, :floor, :room, :area)
    all.each do |location|
      # a location should always have a building
      buildings[location.building] ||= {}
      floors = buildings[location.building]

      if location.floor
        floors[location.floor] ||= {}
        rooms = floors[location.floor]
      else
        floors['[no floor]'] ||= {}
        rooms = floors['[no floor]']
      end

      if location.room
        rooms[location.room] ||= []
        areas = rooms[location.room]
      else
        rooms['[no room]'] ||= []
        areas = rooms['[no room]']
      end

      next if location.area.nil?
      areas.push(location.area) unless areas.include? location.area
    end

    buildings
  end

  def self.for_building(building, floor = nil, room = nil, area = nil)
    query = {
      :building => building
    }
    query[:floor] = floor if floor && floor != ''
    query[:room] = room if room && room != ''
    query[:area] = area if area && area != ''

    self.filter(query).all
  end
end
