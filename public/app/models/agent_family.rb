class AgentFamily < Record

  def metadata
    md = {
      '@context' => "http://schema.org/",
      '@type' => 'Organization',
      '@id' => AppConfig[:public_proxy_url] + uri,
      'name' => json['display_name']['sort_name'],
      'sameAs' => raw['authority_id'],
      'alternateName' => json['names'].select{|n| !n['is_display_name']}.map{|n| n['sort_name']}
    }

    if (dates = json['dates_of_existence'].first)
      md['foundingDate'] = dates['begin'] if dates['begin']
      md['dissolutionDate'] = dates['end'] if dates['end']
    end

    md['description'] = json['notes'].select{|n| n['jsonmodel_type'] == 'note_bioghist'}.map{|note|
                          strip_mixed_content(note['subnotes'].map{|s| s['content']}.join(' '))
                        }
    md['description'] = md['description'][0] if md['description'].length == 1

    md.compact.delete_if { |key,value| value.empty? }
  end


  def related_agents
    ASUtils.wrap(json['related_agents']).select{|rel|
      rel['_resolved']['publish']
    }
  end

end
