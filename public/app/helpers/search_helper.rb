module SearchHelper


  def configure_index_results_view
    results_view_config = @search_data.index_results_view_settings
    unless results_view_config.nil?
      instance_eval &results_view_config
    end
  end

  def allow_multi_select?
    @show_multiselect_column
  end


  def show_record_type?
    !@search_data.single_type? || (@search_data[:criteria].has_key?("type[]") && @search_data[:criteria]["type[]"].include?("agent"))
  end


  def show_title_column?
    @search_data.has_titles?
  end


  def title_column_header(title_header)
    @title_column_header = title_header
  end


  def title_column_header_label
    @title_column_header or I18n.t("search_results.result_title")
  end


  def title_sort_label
    @title_column_header or I18n.t("search_sorting.title_sort")
  end



  def add_column(label, block, opts = {})
    @extra_columns ||= []

    if opts[:sortable] && opts[:sort_by]
      @search_data.sort_fields << opts[:sort_by]
    end

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
