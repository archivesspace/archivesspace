class ExtentCalculator

  attr_reader :units

  Unit_conversions = {
    :inches => {
      :centimeters => 2.54,
      :feet => 1.0/12.0,
      :meters => 0.0254
    },
    :centimeters => {
      :inches => 0.393701,
      :feet => 0.0328084,
      :meters => 0.01
    },
    :feet => {
      :inches => 12.0,
      :centimeters => 2.54*12.0,
      :meters => 0.3048
    },
    :meters => {
      :inches => 39.3701,
      :feet => 3.28084,
      :centimeters => 100.0
    }
  }

  def initialize(obj, strict = false, calculate = true)
    @root_object = obj
    @resource = obj.respond_to?(:root_record_id) ? obj.class.root_model[obj.root_record_id] : nil
    @strict = strict
    @calculated_extent = nil
    @volume = false
    @units = nil
    @decimal_places_in_published_extent = 2
    @container_count = 0
    @container_without_profile_count = 0
    @containers = {}
    @calculated = false
    @timestamp = nil

    if AppConfig.has_key?(:container_management_extent_calculator)
      cfg = AppConfig[:container_management_extent_calculator]
      @volume = cfg.has_key?(:report_volume) && cfg[:report_volume]
      @decimal_places_in_published_extent = cfg[:decimal_places] if cfg.has_key?(:decimal_places)
      self.units = cfg[:unit] if cfg.has_key?(:unit)
    end

    total_extent if calculate
  end


  def units=(unit)
    return @units if @units == unit
    raise "Unrecognized unit" unless Unit_conversions.keys.include? unit
    old_unit = @units
    @units = unit
    if @calculated_extent
      @calculated_extent = convert(@calculated_extent, old_unit)
      @containers.each_value do |val|
        val[:extent] = convert(val[:extent], old_unit)
      end
    end
    @units
  end


  def containers(name = nil)
    if name
      con = @containers[name]
      {:count => con[:count], :extent => published_extent(con[:extent])}
    else
      pub_containers = {}
      @containers.each do |k, con|
        pub_containers[k] = {:count => con[:count], :extent => published_extent(con[:extent])}
      end
      pub_containers
    end
  end


  def total_extent(recalculate = false)
    return published_extent if @calculated_extent && !recalculate

    extent = 0

    topcon_rlshp = SubContainer.find_relationship(:top_container_link)
    rel_ids = @root_object.object_graph.ids_for(topcon_rlshp)

    DB.open do |db|
      db[:top_container_link_rlshp].filter(:id => rel_ids).select(:top_container_id).
        distinct().map{|hash| hash[:top_container_id]}.each do |tc_id|

        @container_count += 1

        if (rec = TopContainer[tc_id].related_records(:top_container_profile))
          key = @volume ? rec.name : rec.display_string
          @containers[key] ||= {:count => 0, :extent => 0.0}
          @containers[key][:count] += 1
          ext = if @volume
                  vol = 1.0
                  [:width, :height, :depth].each {|dim| vol = rec.send(dim).to_f * vol }
                  convert(vol, rec.dimension_units.intern)
                else
                  convert(rec.send(rec.extent_dimension.intern).to_f, rec.dimension_units.intern)
                end
          @containers[key][:extent] += ext
          extent += ext
        else
          # top container does not have a container profile
          if @strict
            raise "Container without Profile found"
          else
            @container_without_profile_count += 1
          end
        end
      end
    end

    @calculated = true
    @calculated_extent = extent
    @timestamp = Time.now
    published_extent
  end


  def to_hash
    {
      :object => {:uri => @root_object.uri, :jsonmodel_type => @root_object.class.my_jsonmodel.record_type,
        :title => @root_object.title || @root_object.display_string},
      :resource => @resource ? {:uri => @resource.uri, :title => @resource.title} : nil,
      :total_extent => published_extent,
      :container_count => @container_count,
      :container_without_profile_count => @container_without_profile_count,
      :units => @units,
      :volume => @volume,
      :containers => containers,
      :timestamp => @timestamp.iso8601
    }
  end


  private

  def convert(val, unit)
    @units ||= unit
    return val if unit == @units
    conv = Unit_conversions[unit][@units]
    conv = conv**3 if @volume
    val * conv
  end


  def published_extent(extent = nil)
    extent ? extent.round(@decimal_places_in_published_extent) :
      @calculated_extent.round(@decimal_places_in_published_extent)
  end

end
