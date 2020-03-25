class AgentPerson < Record

  def metadata
    md = {
      '@context' => "http://schema.org/",
      '@type' => 'Person',
      '@id' => AppConfig[:public_proxy_url] + uri,
      'name' => json['display_name']['sort_name'],
      'sameAs' => raw['authority_id'],
      'alternateName' => json['names'].select{|n| !n['is_display_name']}.map{|n| n['sort_name']}
    }

    if (dates = json['dates_of_existence'].first)
      md['birthDate'] = dates['begin'] if dates['begin']
      md['deathDate'] = dates['end'] if dates['end']
    end

    md['description'] = json['notes'].select{|n| n['jsonmodel_type'] == 'note_bioghist'}.map{|note|
                          strip_mixed_content(note['subnotes'].map{|s| s['content']}.join(' '))
                        }
    md['description'] = md['description'][0] if md['description'].length == 1

    md['knows'] = json['related_agents'].select{|ra|
      ra['relator'] == 'is_associative_with' && ra['_resolved']['jsonmodel_type'] == json['jsonmodel_type']}.map do |ag|
      res = ag['_resolved']

      out = {}
      out['@id'] = res['display_name']['authority_id'] if res['display_name']['authority_id']
      out['name'] = res['display_name']['sort_name']
      out['url'] = AppConfig[:public_proxy_url] + res['uri']

      knows = {}

      if ag['dates']
        knows['startDate'] = ag['dates']['begin'] if ag['dates']['begin']
        knows['endDate'] = ag['dates']['end'] if ag['dates']['end']
      end

      knows['description'] = ag['description'] if ag['description']
      knows['@type'] = 'Role' unless knows.empty?

      out['knows'] = knows unless knows.empty?

      out
    end

    md['parent'] = json['related_agents'].select{|ra| ra['relator'] == 'is_child_of'}.map do |ag|
      res = ag['_resolved']
      out = {}
      out['@id'] = res['display_name']['authority_id'] if res['display_name']['authority_id']
      out['name'] = res['display_name']['sort_name']
      out['url'] = AppConfig[:public_proxy_url] + res['uri']

      out
    end

    md['children'] = json['related_agents'].select{|ra| ra['relator'] == 'is_parent_of'}.map do |ag|
      res = ag['_resolved']
      out = {}
      out['@id'] = res['display_name']['authority_id'] if res['display_name']['authority_id']
      out['name'] = res['display_name']['sort_name']
      out['url'] = AppConfig[:public_proxy_url] + res['uri']

      out
    end

    md['affiliation'] = json['related_agents'].select{|ra|
      ra['relator'] == 'is_associative_with' && ra['_resolved']['jsonmodel_type'] != json['jsonmodel_type']}.map do |ag|
      res = ag['_resolved']
      out = {}
      out['@id'] = res['display_name']['authority_id'] if res['display_name']['authority_id']
      out['name'] = res['display_name']['sort_name']
      out['url'] = AppConfig[:public_proxy_url] + res['uri']

      out
    end

    md.compact.delete_if { |key,value| value.empty? }
  end


  def related_agents
    ASUtils.wrap(json['related_agents']).select{|rel|
      rel['_resolved']['publish']
    }
  end

end
