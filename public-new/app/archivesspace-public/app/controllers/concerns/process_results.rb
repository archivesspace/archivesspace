module ProcessResults
  extend ActiveSupport::Concern
# process search results in one place, including stripping 0-value facets, and JSON-izing any expected JSON

  def handle_results(results, no_zero = true)
    if no_zero && !results['facets'].blank? && !results['facets']['facet_fields'].blank?
      results['facets']['facet_fields'] = strip_facet_fields(results['facets']['facet_fields'])
    end
    results['results'] = process_results(results['results'])
    results
  end
  def process_results(results)
    results.each do |result|
      if !result['json'].blank?
        result['json'] = JSON.parse(result['json']) || {}
      end
      # the info is deeply nested; find & bring it up 
      if result['_resolved_repository'].kind_of?(Hash) 
        rr = result['_resolved_repository'].shift
        if !rr[1][0]['json'].blank?
          result['_resolved_repository']['json'] = JSON.parse( rr[1][0]['json'])
        end
      end
      # I'm going to assume for today that the same holds true for this
      if result['_resolved_resource'].kind_of?(Hash)
        rr = result['_resolved_resource'].shift
        if !rr[1][0]['json'].blank?
          result['_resolved__resource']['json'] =  JSON.parse( rr[1][0]['json'])
        end
      end
    end
    results
  end

# we don't want any 'ead/' or 'archdesc/' stuff
  def strip_facet_fields(facet_fields)
    facet_fields.each do |key, arr|
      facets = {}
      arr.each_slice(2) do |t, ct|
        next if (ct == 0)
        next if t.start_with?("ead/ archdesc/ ")
        facets[t] = ct
      end
      facet_fields[key] = facets
    end
    facet_fields
  end


end
