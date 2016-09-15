module HandleFaceting
  extend ActiveSupport::Concern

  # does the fetches when you only want facet information

  def fetch_facets(query, facets_array, include_zero)
#    Rails.logger.debug("Finding facets for query '#{query}'")
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

  # 
  def adjust_facet_filters(facets_arr, filters_arr)
    adjusted = []
    if facets_arr && filters_arr
      filters_arr.collect! {|f| f.split[":"][0]}
      
    end
    adjusted
  end

  # strip out: facets with counts less than input minimum or equal to the total hits, facets of form "ead/ arch*"
  # returns a hash with the text of the facet as the key, count as the value
  def strip_facets(facets_array, min, total_hits = nil)
    facets = {}
    facets_array.each_slice(2) do |t, ct|
      next if ct < min
      next if total_hits && ct == total_hits
      next if t.start_with?("ead/ archdesc/ ")
      facets[t] = ct
    end
    facets
  end
   # bury the mess! 
  def get_pretty_facet_value(k, v)
#    Rails.logger.debug("input v: #{v}")
    pv = strip_mixed_content(v)
    if (k == 'primary_type')
      pv = I18n.t("#{v}._singular")
    end
    pv
  end



end
