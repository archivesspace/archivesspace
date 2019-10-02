# QSA NOTE: This version of the date calculator has been optimised for
# collections with record counts in the millions.  It's roughly compatible with
# the standard ArchivesSpace date calculator, *except* that it assumes all dates
# will be in strict iso8601 format.
#
# Specifically, the padding is significant.  We need 2000-01-01 and never
# 2000-1-1.

class DateCalculator

  attr_reader :min_begin, :max_end, :min_begin_date, :max_end_date

  def initialize(obj, label = nil, calculate = true, opts = {})
    @root_object = obj

    @resource = obj.respond_to?(:root_record_id) ? obj.class.root_model[obj.root_record_id] : @root_object
    @label = label

    @opts = opts
    # Supported opts:
    #   :allow_open_end - if set to true then accept nil end dates, otherwise default to begin

    @min_begin = nil
    @min_begin_date = nil
    @max_end = nil
    @max_end_date = nil

    calculate! if calculate
  end

  def calculate!
    DB.open do |db|
      # substring/concat trickery: pad each date to the maximum extent possibly
      # needed and then substring to chop off the excess.
      date_query = db[:date]
                     .filter(Sequel.|(Sequel.~(:begin => nil), Sequel.~(:end => nil)))
                     .select(Sequel.lit('min(begin) min_begin'),
                             Sequel.lit('max(substring(concat(begin, "-99-99"), 1, 10)) max_begin_padded'),
                             Sequel.lit('max(substring(concat(end, "-99-99"), 1, 10)) max_end_padded'))


      if @label
        label_id = BackendEnumSource.id_for_value('date_label', @label)
        date_query = date_query.filter(:label_id => label_id)
      end

      if @root_object.is_a?(Resource)
        ao_ids = db[:archival_object]
                  .filter(:root_record_id => @root_object.id)
                  .select(:id)

        # Index hitery trickery: handle resources and AOs as two independent
        # subqueries so that we hit the right indexes in each case.  Union the
        # result because that's cheap.
        #
        # Time to calculate dates for 32 resources dropped from 7 seconds to
        # 200ms with this change, so who's laughing now...
        date_query_resource = date_query.filter(:resource_id => @resource.id)
        date_query_ao = date_query.filter(:archival_object_id => ao_ids)

        date_query = date_query_resource.union(date_query_ao).select(Sequel.lit('min(min_begin) min_begin'),
                                                                     Sequel.lit('max(max_begin_padded) max_begin_padded'),
                                                                     Sequel.lit('max(max_end_padded) max_end_padded'))
      else
        ao_ids = [@root_object.id]
        parent_ids = [@root_object.id]

        while(true) do
          ids = db[:archival_object]
                 .filter(:parent_id => parent_ids)
                 .select(:id)
                 .map{|row| row[:id]}

          if ids.empty?
            break
          else
            ao_ids.concat(ids)
            parent_ids = ids
          end
        end

        date_query = date_query.filter(:archival_object_id => ao_ids)
      end

      result = date_query.first

      if result.fetch(:min_begin)
        @min_begin = result.fetch(:min_begin)
        @min_begin_date = coerce_begin_date(result.fetch(:min_begin))
      end

      if result.fetch(:max_end_padded)
        @max_end = strip_date_padding(result.fetch(:max_end_padded))
        @max_end_date = coerce_end_date(@max_end)
      elsif !@opts[:allow_open_end] && result.fetch(:max_begin_padded)
        # Try the begin date
        @max_end = strip_date_padding(result.fetch(:max_begin_padded))
        @max_end_date = coerce_end_date(@max_end)
      end
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

    if raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/
      Date.strptime(raw_date, '%Y-%m-%d')
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]$/
      Date.strptime("#{raw_date}-01", '%Y-%m-%d')
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]$/
      Date.strptime("#{raw_date}-01-01", '%Y-%m-%d')
    else
      raise "Not a date: #{raw_date}"
    end
  end

  def coerce_end_date(raw_date)
    return if raw_date.nil?

    if raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/
      Date.strptime(raw_date, '%Y-%m-%d')
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]$/
      year, month = raw_date.match(/([0-9][0-9][0-9][0-9])-([0-9][0-9])/).captures
      Date.civil(year.to_i, month.to_i, -1)
    elsif raw_date =~ /^[0-9][0-9][0-9][0-9]$/
      Date.civil(raw_date.to_i, -1, -1)
    else
      raise "Not a date: #{raw_date}"
    end
  end

  def strip_date_padding(s)
    # Our SQL query will append '-99' to pad missing months and days as needed.
    # Take those off now.
    s.gsub(/(-99)+/, '')
  end

end
