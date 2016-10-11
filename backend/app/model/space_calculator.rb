class SpaceCalculator

  MAX_CONTAINERS_TO_PACK = 99999

  class UnsupportedUnitException < StandardError
  end

  class MissingDimensionException < StandardError
  end

  attr_reader :units

  def initialize(container_profile, locations)
    @container_profile = container_profile
    @locations = locations
    @total_spaces_available = 0
    @total_containers_of_type = 0
    @locations_with_space = []
    @locations_without_space = []
    @uncalculatable_locations = []

    calculate
  end


  def to_hash
    {
      'container_profile' => {'ref' => @container_profile.uri},
      'total_spaces_available' => @total_spaces_available,
      'total_containers_of_type' => @total_containers_of_type,
      'locations_with_space' => @locations_with_space,
      'locations_without_space' => @locations_without_space,
      'uncalculatable_locations' => @uncalculatable_locations
    }
  end


  private

  def calculate
    cp_dims = Dimensions.new(@container_profile.width,
                             @container_profile.height,
                             @container_profile.depth,
                             @container_profile.dimension_units)

    location_containers = LocationContainerLookup.new(@locations)

    @locations.each do |loc|
      location_profile = location_containers.location_profile_for(loc)

      if location_profile.nil?
        # the location doesn't have a profile so not much we can do
        @uncalculatable_locations << {'ref' => loc.uri, 'reason' => :location_lacks_a_profile}
        next
      end

      begin
        lp_dims = Dimensions.new(location_profile.width,
                                 location_profile.height,
                                 location_profile.depth,
                                 location_profile.dimension_units)
      rescue MissingDimensionException
        # the location's profile doesn't have the necessary data
        @uncalculatable_locations << {'ref' => loc.uri, 'reason' => :location_lacks_dimension_data}
        next
      end

      if cp_dims.bigger_in_any_than?(lp_dims)
        # the container is bigger than the location in at least one dimension
        @locations_without_space << {'ref' => loc.uri, 'reason' => :container_is_bigger}
        next
      end

      # if we're still here then we'll have to run the packer to find out if it fits

      # get a location packer
      packer = LocationPacker.new(lp_dims)

      # find the current containers at this location
      container_profiles = location_containers.container_profiles_at_location(loc)

      # pack the current containers into the location
      hit_error = false
      container_profiles.each do |tcp|
        if tcp.nil?
          # need to say uncalculatable and get out
          @uncalculatable_locations << {'ref' => loc.uri, 'reason' => :container_at_location_lacks_profile}

          hit_error = true
          break
        end

        @total_containers_of_type += 1 if tcp.id == @container_profile.id

        unless packer.add_container(tcp.name,
                                    Dimensions.new(tcp.width,
                                                   tcp.height,
                                                   tcp.depth,
                                                   tcp.dimension_units),
                                    tcp.stacking_limit)
          # this shouldn't happen - we're just packing the containers already at the location
          # we'll have to add it to uncalculatable and get out
          @uncalculatable_locations << {'ref' => loc.uri, 'reason' => :containers_at_location_dont_fit}
          hit_error = true
          break
        end
      end

      # If we missed any of the required data for this location, skip over it.
      next if hit_error

      # Now that the packer is pre-populated with the existing containers, we're
      # ready to start trying to add our containers and count how many fit
      count = 0
      while packer.add_container(@container_profile.name,
                                 Dimensions.new(@container_profile.width,
                                                @container_profile.height,
                                                @container_profile.depth,
                                                @container_profile.dimension_units),
                                 @container_profile.stacking_limit)
        count += 1

        # peace of mind
        break if count > MAX_CONTAINERS_TO_PACK
      end

      if count == 0
        @locations_without_space << {'ref' => loc.uri, 'reason' => :location_cannot_fit_container}
      else
        @total_spaces_available += count
        @locations_with_space << {'ref' => loc.uri, 'count' => count}
      end
    end
  end


  # Encapsulate our DB queries for efficiently getting the
  # location/container/profile information we need.
  class LocationContainerLookup

    def initialize(locations)
      calculate(locations)
    end

    def location_profile_for(location)
      #location.related_records(:location_profile)
      @locations_to_location_profiles[location.id]
    end

    def container_profiles_at_location(location)
      #TopContainer.find_relationship(:top_container_housed_at).who_participates_with(location)
      Array(@locations_to_container_profiles[location.id])
    end

    private

    def calculate(locations)
      build_location_to_profile_mapping
      build_container_profile_mapping
    end

    def build_location_to_profile_mapping
      DB.open do |db|
        location_profile_rlshp = Location.find_relationship(:location_profile)

        location_ids_to_profile_ids = {}

        db[:location]
          .join(location_profile_rlshp.table_name, :location_id => Sequel.qualify(:location, :id))
          .select(Sequel.as(:location__id, :location_id),
                  Sequel.as(Sequel.qualify(location_profile_rlshp.table_name, :location_profile_id),
                            :location_profile_id)).each do |row|
          location_ids_to_profile_ids[row[:location_id]] = row[:location_profile_id]
        end

        location_profiles_lookup = Hash[LocationProfile
                                         .filter(:id => location_ids_to_profile_ids.values.uniq)
                                         .map {|profile| [profile.id, profile]}]

        @locations_to_location_profiles = Hash[location_ids_to_profile_ids.map {|location_id, profile_id|
                                                 [location_id, location_profiles_lookup[profile_id]]
                                               }]
      end
    end

    def build_container_profile_mapping
      DB.open do |db|
        housed_at_rlshp = TopContainer.find_relationship(:top_container_housed_at)
        profile_rlshp = TopContainer.find_relationship(:top_container_profile)

        location_ids_to_container_profile_ids = {}

        db[:location]
          .join(housed_at_rlshp.table_name, :location_id => Sequel.qualify(:location, :id))
          .left_join(profile_rlshp.table_name, :top_container_id => Sequel.qualify(housed_at_rlshp.table_name, :top_container_id))
          .select(Sequel.as(:location__id, :location_id),
                  Sequel.as(Sequel.qualify(profile_rlshp.table_name, :container_profile_id),
                            :container_profile_id)).each do |row|
          location_ids_to_container_profile_ids[row[:location_id]] ||= []
          location_ids_to_container_profile_ids[row[:location_id]] << row[:container_profile_id]
        end

        container_profiles_lookup = Hash[ContainerProfile
                                          .filter(:id => location_ids_to_container_profile_ids.values.flatten.compact.uniq)
                                          .map {|profile| [profile.id, profile]}]

        @locations_to_container_profiles = Hash[location_ids_to_container_profile_ids.map {|location_id, profile_ids|
                                                  [location_id, profile_ids.map {|profile_id|
                                                     if profile_id
                                                       container_profiles_lookup.fetch(profile_id)
                                                     else
                                                       # A container without a container profile.  Return a nil.
                                                       nil
                                                     end
                                                   }]
                                               }]
      end
    end
  end


  class LocationPacker

    def initialize(dimensions)
      @dimensions = dimensions
      @piles = []
    end


    # Some types of containers can't be stacked on top of each other.  The
    # `max_tower_count` parameter lets you specify the maximum number of levels
    # a container can be stacked on top of each other.
    def add_container(name, dimensions, max_tower_count)
      container = Container.new(name, dimensions, (max_tower_count || :unlimited))

      pile = find_pile_for(container)

      if pile
        pile.add(container)
      else
        pile = Pile.new(@dimensions)
        pile.add(container)
        if pile_fits?(pile)
          @piles << pile
        else
          return false
        end
      end

      true
    end


    def find_pile_for(container)
      @piles.each do |pile|
        if pile.will_fit(container)
          return pile
        end
      end

      false
    end


    def pile_fits?(pile)
      return false if pile.height > @dimensions.height || pile.depth > @dimensions.depth
      piles_width = 0
      @piles.each do |pile|
        piles_width += pile.width
      end

      (piles_width + pile.width) <= @dimensions.width
    end


    class Pile

      def initialize(location_dims)
        @location_dims = location_dims
        @containers = []
      end


      def add(container)
        @containers << container
      end


      def width
        @containers[0].dimensions.width
      end


      def height
        @containers[0].dimensions.height
      end


      def depth
        @containers[0].dimensions.depth
      end


      def will_fit(container)
        if @containers.length > 0 && @containers[0].name != container.name
          return false
        end

        @containers.length < max_container_count
      end


      def containers_per_tower
        container = @containers[0]
        number_that_fit = (@location_dims.height / container.dimensions.height).to_i

        # If there's a limit on how high we can stack these, cap it.
        if container.max_tower_count != :unlimited
          number_that_fit = [number_that_fit, container.max_tower_count].min
        end

        number_that_fit
      end


      def max_container_count
        number_of_towers = (@location_dims.depth / @containers[0].dimensions.depth).to_i

        containers_per_tower * number_of_towers
      end

    end


    class Container
      attr_reader :name, :dimensions, :max_tower_count

      def initialize(name, dimensions, max_tower_count)
        @name = name
        @dimensions = dimensions
        @max_tower_count = (max_tower_count == :unlimited) ? :unlimited : Integer(max_tower_count)
      end
    end
  end


  class Dimensions
    attr_reader :width, :height, :depth, :provided_unit

    WORKING_UNIT = :millimeters

    UNIT_CONVERSIONS = {
      :millimeters => {
        :centimeters => 0.1,
        :meters => 0.001,
        :inches => 0.0393701,
        :feet => 0.00328084,
        :yards => 0.00328084/3.0,
      },
      :centimeters => {
        :millimeters => 10.0,
        :meters => 0.01,
        :inches => 0.393701,
        :feet => 0.0328084,
        :yards => 0.0328084/3.0,
      },
      :meters => {
        :millimeters => 1000.0,
        :centimeters => 100.0,
        :inches => 39.3701,
        :feet => 3.28084,
        :yards => 3.28084/3.0,
      },
      :inches => {
        :millimeters => 25.4,
        :centimeters => 2.54,
        :meters => 0.0254,
        :feet => 1.0/12.0,
        :yards => 1.0/36.0,
      },
      :feet => {
        :millimeters => 25.4*12.0,
        :centimeters => 2.54*12.0,
        :meters => 0.3048,
        :inches => 12.0,
        :yards => 1.0/3.0,
      },
      :yards => {
        :millimeters => 25.4*36.0,
        :centimeters => 2.54*36.0,
        :meters => 0.3048*3.0,
        :inches => 36.0,
        :feet => 3.0,
      },
    }


    def initialize(width, height, depth, unit = nil)
      @provided_unit = (unit ? unit.intern : :inches)
      unless UNIT_CONVERSIONS.has_key?(@provided_unit)
        raise UnsupportedUnitException.new("Provided unit not supported: #{@provided_unit}")
      end
      if width.nil? || height.nil? || depth.nil?
        raise MissingDimensionException.new("Values must be provided for width (#{width}), height (#{height}) and depth (#{depth})")
      end
      @width = convert(width.to_f)
      @height = convert(height.to_f)
      @depth = convert(depth.to_f)
    end


    def convert(val)
      return val if @provided_unit == WORKING_UNIT
      conv = UNIT_CONVERSIONS.fetch(@provided_unit, {}).fetch(WORKING_UNIT)
      val * conv
    end


    def bigger_in_any_than?(other_dim)
      @width > other_dim.width || @height > other_dim.height || @depth > other_dim.depth
    end


    def has_missing_dimension?
      # if initialized with nil the .to_f will coerce it to 0.0
      @width == 0.0 || @height == 0.0 || @depth == 0.0
    end

  end

end
