module SearchHelper

  def show_record_type?
    !@search_data.single_type? || (@search_data[:criteria].has_key?("type[]") && @search_data[:criteria]["type[]"].include?("agent"))
  end

  def add_column(label, block, opts = {})
    @extra_columns ||= []

    col = ExtraColumn.new(label, block, opts, @search_data)
    @extra_columns.push(col)
  end

  def extra_columns
    @extra_columns
  end

  def extra_columns?
    return false if @extra_columns == nil

    !@extra_columns.empty?
  end

  class ExtraColumn
    def initialize(label, value_block, opts, search_data)
      @label = label
      @value_block = value_block
      @classes = "col " << (opts[:class] || "")
      @sortable = opts[:sortable] || false
      @sort_by = opts[:sort_by] || ""
      @search_data = search_data
    end

    def value_for(record)
      @value_block.call(record)
    end

    def label
      @label
    end

    def sortable?
      @sortable
    end

    def sort_by
      @sort_by
    end

    def class
      @classes << " sortable" if sortable?
      @classes << " sort-#{@search_data.current_sort_direction}" if sortable? && @search_data.sorted_by === @sort_by
      @classes
    end
  end

end