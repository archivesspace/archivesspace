class Resource < Record
  include ResourceRequestItems

  attr_reader :digital_instances, :finding_aid, :related_accessions,
              :related_deaccessions, :cite

  def initialize(*args)
    super

    @digital_instances = parse_digital_instance
    @finding_aid = parse_finding_aid
    @related_accessions = parse_related_accessions
    @cite = parse_cite_string
  end

  def breadcrumb
    [
      {
        :uri => '',
        :type => 'resource',
        :crumb => display_string
      }
    ]
  end

  def ead_id
    @json['ead_id']
  end

  # Return the four parts as an array
  #
  # The result might contain nils if not all parts were present.
  def four_part_identifier
    (0..3).map {|part| @json["id_#{part}"]}
  end

  def metadata
    md = {
      '@context' => ["http://schema.org/", {'library' => 'http://purl.org/library/'}],
      '@type' => ['schema:CreativeWorkSeries', 'library:ArchiveMaterial'],
      'name' => display_string,
      'url' => AppConfig[:public_proxy_url] + uri,
      'identifier' => raw['four_part_id'],
    }

    md['description'] = json['notes'].select{|n| n['type'] == 'abstract'}.map{|abstract|
                          strip_mixed_content(abstract['content'].join(' '))
                        }

    if md['description'].empty?
      md['description'] = json['notes'].select{|n| n['type'] == 'scopecontent'}.map{|scope|
                            strip_mixed_content(scope['subnotes'].map{|s| s['content']}.join(' '))
                          }
    end
    md['description'] = md['description'][0] if md['description'].length == 1


    md['creator'] = json['linked_agents'].select{|la| la['role'] == 'creator'}.map{|a| a['_resolved']}.map do |ag|
      {
        '@id' => ag['display_name']['authority_id'],
        '@type' => ag['jsonmodel_type'] == 'agent_person' ? 'Person' : 'Organization',
        'name' => ag['title']
      }
    end

    term_type_to_about_type = {
      'geographic' => 'Place',
      'temporal' => 'TemporalCoverage',
      'uniform_title' => 'CreativeWork',
      'topical' => 'Intangible',
      'occupation' => 'Intangible'
    }

    md['about'] = json['subjects'].select{|s|
      term_type_to_about_type.keys.include?(s['_resolved']['terms'][0]['term_type'])
    }.map{|s| s['_resolved']}.map{|subj|
      hash = {'@type' => term_type_to_about_type[subj['terms'][0]['term_type']]}
      hash['@id'] = subj['authority_id'] if subj['authority_id']
      hash['name'] = subj['title']
      hash
    }

    md['about'].concat(json['linked_agents'].select{|la| la['role'] == 'subject'}.map{|a| a['_resolved']}.map{|ag|
                         {
                           '@type' => ag['jsonmodel_type'] == 'agent_person' ? 'Person' : 'Organization',
                           'name' => strip_mixed_content(ag['title']),
                         }
                       })

    md['genre'] = json['subjects'].select{|s|
      s['_resolved']['terms'][0]['term_type'] == 'genre_form'
    }.map{|s| s['_resolved']}.map{|subj|
      subj['authority_id'] ? subj['authority_id'] : subj['title']
    }

    if raw['language'].try(:any?)
         md['inLanguage'] = {
           '@type' => 'Language',
           'name' => I18n.t("enumerations.language_iso639_2.#{raw['language']}", :default => raw['language'])
         }
    end

    md['provider'] = {
      '@id' => json['repository']['_resolved']['agent_representation']['_resolved']['display_name']['authority_id'],
      'url' => AppConfig[:public_proxy_url] + raw['repository'],
      '@type' => 'Organization',
      'name' => json['repository']['_resolved']['name']
    }

    md
  end

  def instances
    json['instances']
  end

  private

  def parse_digital_instance
    dig_objs = []
    if json['instances'] && json['instances'].kind_of?(Array)
      json['instances'].each do |instance|
        unless !instance.dig('digital_object','_resolved')
          dig_f = {}
          it =  instance['digital_object']['_resolved']
          unless it['file_versions'].blank?
            title = strip_mixed_content(it['title'])
            dig_f = process_file_versions(it)
            dig_f['caption'] = CGI::escapeHTML(title) if dig_f['caption'].blank? && !title.blank?
          end
        end
        dig_objs.push(dig_f) unless dig_f.blank?
      end
    end
    dig_objs
  end

  def process_file_versions(json)
    dig_f = {}
    unless json['file_versions'].blank?
      json['file_versions'].each do |version|
        if version.dig('publish') != false && version['file_uri'].start_with?('http')
          unless !json.dig('html','note','note_text')
            dig_f['caption'] =  json['html']['note']['note_text']
          end
          if version.dig('xlink_show_attribute') == 'embed'
            dig_f['thumb'] = version['file_uri']
            dig_f['represent'] = 'embed' if version['is_representative']
          else
            dig_f['represent'] = 'new'  if version['is_representative']
            dig_f['out'] = version['file_uri'] if version['file_uri'] != (dig_f['out'] || '')
          end
        elsif !version['file_uri'].start_with?('http')
          Rails.logger.debug("****BAD URI? #{version['file_uri']}")
        end
      end
    end
    dig_f
  end

  def parse_finding_aid
    fa = {}
    json.keys.each do |k|
      if k.start_with? 'finding_aid'
        fa[k.sub("finding_aid_","")] = strip_mixed_content(json[k])
      elsif k == 'revision_statements'
        revision = []
        v = json[k]
        if v.kind_of? Array
          v.each do |rev|
            revision.push({'date' => rev['date'] || '', 'desc' => rev['description'] || ''})
          end
        else
          if v.kind_of? Hash
            revision.push({'date' => v['date'] || '', 'desc' => v['description'] || ''})
          end
        end
        fa['revision'] = revision
      end
    end
    fa
  end

  def parse_related_accessions
    ASUtils.wrap(raw['related_accession_uris']).collect{|uri|
      if raw['_resolved_related_accession_uris']
        raw['_resolved_related_accession_uris'][uri].first
      end
    }.compact.select{|accession|
      accession['publish']
    }.map {|accession|
      record_from_resolved_json(ASUtils.json_parse(accession['json']))
    }
  end

  def parse_cite_string
    cite = note('prefercite')
    unless cite.blank?
      cite = strip_mixed_content(cite['note_text'])
    else
      cite =  strip_mixed_content(display_string) + '.'
      unless repository_information['top']['name'].blank?
        cite += " #{ repository_information['top']['name']}."
      end
    end
    "#{cite}   #{cite_url_and_timestamp}."
  end

  def parse_notes
    rewrite_refs(json['notes'], uri)

    super
  end

  def parse_resource
    json
  end
end
