class AgentCorporateEntity < Record

  def metadata
    md = {
      '@context' => "http://schema.org/",
      '@type' => 'Organization',
      '@id' => raw['authority_id'],
      'name' => json['display_name']['sort_name'],
      'url' => AppConfig[:public_url] + uri,
      'alternateName' => json['names'].select{|n| !n['is_display_name']}.map{|n| n['sort_name']}
    }

    if (dates = json['dates_of_existence'].first)
      md['foundingDate'] = dates['begin']
      md['dissolutionDate'] = dates['end'] if dates['end']
    end

    md['description'] = if (note = json['notes'].select{|n| n['jsonmodel_type'] == 'note_bioghist'}.first)
                          strip_mixed_content(note['subnotes'].map{|s| s['content']}.join(' '))
                        else
                          ''
                        end

    md
  end

end
