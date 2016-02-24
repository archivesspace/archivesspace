module EnumerationHelper

  def enumeration_simple_filter_params( relationships, value ) 
    pattern = %r{(\+|\-|\&\&|\|\||\!|\(|\)|\{|\}|\[|\]|\^|\"|\~|\*|\?|\ |\:|\\)}
    value.gsub!(pattern) { |match| '\\' + match } 
    relationships.map { |rel| "#{rel}_enum_s:#{value}"  }.join(" OR ") 
  end

end

