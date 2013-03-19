module SearchHelper
  def show_record_type?
    @search_data.single_type? || (@search_data[:criteria].has_key?("type[]") && @search_data[:criteria]["type[]"].include?("agent"))
  end
end