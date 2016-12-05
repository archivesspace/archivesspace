require 'csv'
require_relative 'id_generators/generator_interface'

class DOReport

  attr_reader :items

  BASE_COLUMNS = [
    {:header => "Resource ID",           :proc => Proc.new {|resource, item| resource_id(resource)}},
    {:header => "Ref ID",                :proc => Proc.new {|resource, item| ref_id(item)}},
    {:header => "URI",                   :proc => Proc.new {|resource, item| record_uri(item)}},
    {:header => "Container Indicator 1", :proc => Proc.new {|resource, item, dates, box| indicator_1(box)}},
    {:header => "Container Indicator 2", :proc => Proc.new {|resource, item, dates, box| indicator_2(box)}},
    {:header => "Container Indicator 3", :proc => Proc.new {|resource, item, dates, box| indicator_3(box)}},
    {:header => "Title",                 :proc => Proc.new {|resource, item| record_title(item)}},
    {:header => "Component ID",          :proc => Proc.new {|resource, item| component_id(item)}},
  ]

  SERIES_COLUMNS = [
    {:header => "Series",                :proc => Proc.new { |resource, item, dates, box, series| record_title(series) }}
  ]

  SUBSERIES_COLUMNS = [
    {:header => "Sub-Series",            :proc => Proc.new { |resource, item, dates, box, series, subseries| record_title(subseries) }}
  ]

  BARCODE_COLUMNS = [
    {:header => "Barcode",               :proc => Proc.new {|resource, item, dates, box| barcode(box)}}
  ]

  DATES_COLUMNS = [
    {:header => "Dates",                 :proc => Proc.new {|resource, item, dates| date_string(dates)}}
  ]


  def initialize(uris, opts = {})
    @uris = uris
    @generate_ids = opts[:generate_ids]

    if @generate_ids
      Dir.glob(base_dir("id_generators/*.rb")).each do |file|
        require(File.absolute_path(file))
      end

      generator_class = 'DefaultGenerator'
      if AppConfig.has_key?(:digitization_work_order_id_generator) 
        generator_class = AppConfig[:digitization_work_order_id_generator]
      end

      @id_generator = Kernel.const_get(generator_class).new
    end

    @columns = BASE_COLUMNS
    @extras = allowed_extras.select { |e| opts.fetch(:extras) { [] }.include?(e) }
    @extras.each do |extra|
      @columns += self.class.const_get(extra.upcase + '_COLUMNS')
    end

    build_items
  end


  def to_stream
    StringIO.new(@tsv)
  end


  private


  def base_dir(path = nil)
    base = File.absolute_path(File.dirname(__FILE__))
    if path
      File.join(base, path)
    else
      base
    end
  end


  def build_items
    ids = []
    @uris.each do |uri|
      parsed = JSONModel.parse_reference(uri)

      # only archival_objects
      next unless parsed[:type] == "archival_object"

      ids << parsed[:id]
    end

    ds = ArchivalObject
           .select_all(:archival_object)
           .join_table(:left, :archival_object___c, :parent_id => :id)
           .where(Sequel.qualify(:archival_object, :id) => ids, Sequel.qualify(:c, :id) => nil)

    resource = nil
    containers = nil
    dates = get_dates(ids) if @extras.include?('dates')

    @tsv = generate_line(@columns.map {|col| col[:header]})

    ds.each do |ao|
      if @generate_ids && !ao[:component_id]
        ao = generate_id(ao)
      end

      item = {'item' => ao}

      unless resource
        resource = Resource[ao.root_record_id]
        containers = resource.quick_containers
      end

      item['resource'] = resource

      (series, subseries, all) = find_ancestors(ao)
      item['series'] = series
      item['subseries'] = subseries

      all.each do |ancestor|
        item['box'] = containers[ancestor.id]
        break if item['box']
      end

      item['dates'] = dates[ao.id] if @extras.include?('dates')

      add_row_to_report(item)
    end
  end


  def generate_id(ao)
    ao[:component_id] = @id_generator.generate(ao)
    ao.save(:columns => [:component_id, :system_mtime])
    ao
  end


  def get_dates(ids)
    dates = {}
    DB.open do |db|
      db[:date]
        .join(:enumeration_value___label, :id => :label_id)
        .where(:archival_object_id => ids)
        .select(Sequel.as(:date__archival_object_id, :archival_object_id),
                Sequel.as(:label__value, :label),
                Sequel.as(:date__begin, :begin),
                Sequel.as(:date__end, :end),
                Sequel.as(:date__expression, :expression))
        .each do |date|
        dates[date[:archival_object_id]] ||= []
        dates[date[:archival_object_id]] << date
      end
    end
    dates
  end


  def find_ancestors(ao)
    @visited_aos ||= {}
    subseries = nil
    series = nil
    all = [ao]

    while true
      if ao[:parent_id].nil?
        break
      end

      @visited_aos[ao.parent_id] ||= ArchivalObject[ao[:parent_id]]
      ao = @visited_aos[ao.parent_id]

      all << ao
      if ao.level == 'subseries'
        subseries = ao
      end
      if ao.level == 'series'
        series = ao
        break
      end
    end

    return series, subseries, all
  end


  def generate_line(data)
    CSV.generate_line(data, :col_sep => "\t")
  end


  def allowed_extras
    ['series', 'subseries', 'barcode', 'dates']
  end


  def empty_row
    {
      'resource' => {},
      'item' => {},
      'dates' => [],
      'box' => {},
      'series' => {},
      'subseries' => {},
    }
  end


  def add_row_to_report(row)
    mrow = empty_row.merge(row)
    @tsv += generate_line(@columns.map {|col| col[:proc].call(mrow['resource'],
                                                              mrow['item'],
                                                              mrow['dates'],
                                                              mrow['box'],
                                                              mrow['series'],
                                                              mrow['subseries'])})
  end


  # Cell value generators
  def self.record_uri(record)
    record.uri
  end


  def self.record_title(record)
    return '' unless record
    record.title
  end


  def self.resource_id(resource)
    JSON.parse(resource.identifier).compact.join('.')
  end


  def self.ref_id(item)
    item.ref_id
  end


  def self.box_concat(box, &block)
    return '' unless box
    out = box.map { |b| block.call(b) }
    out.compact.join(', ')
  end


  def self.indicator_1(box)
    box_concat(box) { |b| b[:top_container][:indicator] if b[:top_container] }
  end


  def self.barcode(box)
    box_concat(box) { |b| b[:top_container][:barcode] if b[:top_container] }
  end


  def self.indicator_2(box)
    box_concat(box) { |b| b[:sub_container][:indicator_2] }
  end


  def self.indicator_3(box)
    box_concat(box) { |b| b[:sub_container][:indicator_3] }
  end


  def self.component_id(item)
    item[:component_id]
  end


  def self.date_string(dates)
    return '' unless dates
    dates.map { |date|
      dates = [date[:begin], date[:end]].compact.join('--')
      "#{date[:label]}: #{dates}"
    }.join('; ')
  end

end
