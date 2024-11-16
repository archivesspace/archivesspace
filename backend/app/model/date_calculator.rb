class DateCalculator

  attr_reader :min_begin, :max_end, :min_begin_date, :max_end_date

  def initialize(obj, label = nil, calculate = true)
    @root_object = obj

    @resource = obj.respond_to?(:root_record_id) ? obj.class.root_model[obj.root_record_id] : @root_object
    @label = label

    @min_begin = nil
    @min_begin_date = nil
    @max_end = nil
    @max_end_date = nil

    calculate! if calculate
  end

  def calculate!
    DB.open do |db|
      date_query = db[:date]
                     .filter(Sequel.|(Sequel.~(:begin => nil), Sequel.~(:end => nil)))
                     .select(:begin, :end)

      if @root_object.is_a?(Resource)
        ao_ids = db[:archival_object]
                  .filter(:root_record_id => @root_object.id)
                  .select(:id)

        date_query = date_query
                      .filter(:archival_object_id => ao_ids)
      else
        parent_ids = [@root_object.id]
        ao_ids = []

        while (true) do
          ids = db[:archival_object]
                 .filter(:parent_id => parent_ids)
                 .select(:id)
                 .map {|row| row[:id]}

          if ids.empty?
            break
          else
            ao_ids.concat(ids)
            parent_ids = ids
          end
        end

        date_query = date_query
                       .filter(:archival_object_id => ao_ids)
      end

      if @label
        label_id = db[:enumeration_value]
                     .filter(:enumeration_id => db[:enumeration].filter(:name => 'date_label').select(:id))
                     .filter(:value => @label)
                     .select(:id)

        date_query = date_query.filter(:label_id => label_id)
      end

      date_query.map {|row|
        begin_raw = row[:begin]
        end_raw = row[:end] || begin_raw

        begin_date = coerce_begin_date(begin_raw)
        end_date = coerce_end_date(end_raw)

        @min_begin_date = [@min_begin_date, begin_date].compact.min
        @min_begin = begin_raw if @min_begin_date == begin_date

        @max_end_date = [@max_end_date, end_date].compact.max
        @max_end = end_raw if @max_end_date == end_date
      }
    end
  end

  def to_hash
    {
      :object => {:uri => @root_object.uri,
                  :jsonmodel_type => @root_object.class.my_jsonmodel.record_type,
                  :title => @root_object.title || @root_object.display_string,
                  :id => @root_object.id},
      :resource => @resource ? {:uri => @resource.uri, :title => @resource.title} : nil,

      :label => @label,

      :min_begin_date => @min_begin_date,
      :min_begin => @min_begin,
      :max_end_date => @max_end_date,
      :max_end => @max_end
    }
  end

  private

  def coerce_begin_date(raw_date)
    return if raw_date.nil?

    if raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?$/
      Date.strptime(raw_date, '%Y-%m-%d')
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]?$/
      Date.strptime("#{raw_date}-01", '%Y-%m-%d')
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]$/
      Date.strptime("#{raw_date}-01-01", '%Y-%m-%d')
    else
      raise "Not a date: #{raw_date}"
    end
  end

  def coerce_end_date(raw_date)
    return if raw_date.nil?

    if raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]?-[0-9][0-9]?$/
      Date.strptime(raw_date, '%Y-%m-%d')
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]?$/
      year, month = raw_date.match(/([0-9][0-9][0-9][0-9])-([0-9][0-9]?)/).captures
      Date.civil(year.to_i, month.to_i, -1)
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]$/
      Date.civil(raw_date.to_i, -1, -1)
    else
      raise "Not a date: #{raw_date}"
    end
  end

end
