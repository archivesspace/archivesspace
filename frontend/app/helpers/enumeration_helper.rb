require 'advanced_query_builder'

module EnumerationHelper

  def enumeration_advanced_query(relationships, value)
    query = AdvancedQueryBuilder.new

    relationships.each do |rel|
      query.or("#{rel}_enum_s", value, 'text', true)
    end

    query.build.to_json
  end

end

