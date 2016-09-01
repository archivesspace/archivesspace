module ProcessResults
  extend ActiveSupport::Concern
# process search results in one place, including stripping 0-value facets, and JSON-izing any expected JSON
# if req is not nil, process notes for the type matching the value in req, storing the returned html string in
  #  results['json'}["#{type}_html"]
  def handle_results(results, req = nil, no_zero = true)
    if no_zero && !results['facets'].blank? && !results['facets']['facet_fields'].blank?
      results['facets']['facet_fields'] = strip_facet_fields(results['facets']['facet_fields'])
    end
    results['results'] = process_results(results['results'], req)
    results
  end
  def process_results(results, req = nil)
    results.each do |result|
      if !result['json'].blank?
        result['json'] = JSON.parse(result['json']) || {}
      end
      if result['json'].has_key?('notes')
        notes_html =  process_json_notes( result['json']['notes'], req)
        notes_html.each do |type, html|
          result['json']["#{type}_html"] = html
        end
      end
      # the info is deeply nested; find & bring it up 
      if result['_resolved_repository'].kind_of?(Hash) 
        rr = result['_resolved_repository'].shift
        if !rr[1][0]['json'].blank?
          result['_resolved_repository']['json'] = JSON.parse( rr[1][0]['json'])
        end
      end
      # A different kind of convolution
      if result['_resolved_resource'].kind_of?(Hash)
        keys  = result['_resolved_resource'].keys
        if keys
          rr = result['_resolved_resource'][keys[0]]
          result['_resolved_resource']['json'] =  rr[0]
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
