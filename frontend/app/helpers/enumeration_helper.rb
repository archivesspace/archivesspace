module EnumerationHelper

  def enumeration_simple_filter_params( relationships, value ) 
    relationships.map { |rel| "#{rel}_enum_s:#{value}"  }.join(" OR ") 
  end

end

