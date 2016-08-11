module HandleFaceting
  extend ActiveSupport::Concern

  # does the fetches when you only want facet information

  def fetch_facets(query, facets_array, include_zero)
    Rails.logger.debug("Finding facets for query '#{query}'")
    criteria = {}
    criteria[:page_size] = 1
    criteria['facet[]'] = facets_array
    criteria['facet.mincount'] = 1 if !include_zero
    data =  archivesspace.search(query, 1, criteria) || {}
    faceting = {}
    if !data['facets'].blank? && !data['facets']['facet_fields'].blank?
      faceting = data['facets']['facet_fields']
    end
   end

end
