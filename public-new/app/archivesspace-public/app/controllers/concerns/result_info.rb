module ResultInfo
  extend ActiveSupport::Concern

  # extract the repository agent info
  def process_repo_info(result)
    info = {}
    info['top'] = {}
    unless result['_resolved_repository'].blank? ||  result['_resolved_repository']['json'].blank?
      repo =  result['_resolved_repository']['json']
      %w(name uri url parent_institution_name image_url repo_code).each do | item |
        info['top'][item] = repo[item] unless repo[item].blank?
      end
      unless repo['agent_representation'].blank? || repo['agent_representation']['_resolved'].blank? || repo['agent_representation']['_resolved']['jsonmodel_type'] != 'agent_corporate_entity'
        in_h = repo['agent_representation']['_resolved']['agent_contacts'][0]
        %w{city region post_code country email }.each do |k|
          info[k] = in_h[k] if in_h[k].present?
        end
        if in_h['address_1'].present?
          info['address'] = []
          [1,2,3].each do |i|
            info['address'].push(in_h["address_#{i}"]) if in_h["address_#{i}"].present?
          end
        end
        info['telephones'] = in_h['telephones'] if !in_h['telephones'].blank?
      end
    end
   info
  end

  # create the breadcrumbs
  def breadcrumb_info
    context = get_path(@tree)
    # TODO: This is a monkey patch for digital objects
    if context.blank?
      context = []
      unless !@result.dig('_resolved_resource','json')
        context.unshift({:uri => @result['_resolved_resource']['json']['uri'],
                          :crumb => strip_mixed_content(@result['_resolved_resource']['json']['title'])})
      end
    end
    context.unshift({:uri => @result['_resolved_repository']['json']['uri'], :crumb =>  @result['_resolved_repository']['json']['name']})
    context.push({:uri => '', :crumb => strip_mixed_content(@result['json']['display_string'] || @result['json']['title']) })
    context
  end
# create a usable agent hash
  def process_agents(agents_arr, subjects_arr = [])
    agents_h = {}
    agents_arr.each do |agent|
      unless agent['role'].blank? || agent['_resolved'].blank? 
        role = agent['role']
        ag = title_and_uri(agent['_resolved'], agent['_inherited'])
        if role == 'subject'
         subjects_arr.push(ag) if ag 
        elsif ag
          agents_h[role] = agents_h[role].blank? ? [ag] : agents_h[role].push(ag)
        end
      end
    end
    subjects_arr.sort_by! { |hsh| hsh['title'] }
    agents_h
  end

# create a usable subjects array
  def process_subjects(subjects_arr)
    return_arr = []
    subjects_arr.each do |subject|
      unless subject['_resolved'].blank?
        sub = title_and_uri(subject['_resolved'], subject['_inherited'])
        return_arr.push(sub) if sub
      end
    end
    return_arr
  end

# return a title/uri hash if publish == true
  def title_and_uri(in_h, inh_struct = nil)
    ret_val = nil
    if in_h['publish']
      ret_val = in_h.slice('uri', 'title')
      ret_val['inherit'] = inheritance(inh_struct)
      Rails.logger.debug(ret_val)
    end
    ret_val
  end


# cite
  def fill_cite
    @cite = ''
    cite = get_note(@result['json'], 'prefercite')
    unless cite.blank?
      @cite = strip_mixed_content(cite['note_text'])
    else
      @cite = strip_mixed_content(@result['json']['title']) + "."
      ttl = @result.dig('_resolved_resource', 'json', 'title')
      @cite += " #{strip_mixed_content(ttl)}." unless !ttl
      @cite += " #{ @repo_info['top']['name']}." unless @repo_info['top']['name'].blank?
    end
    @cite += "   #{request.original_url}  #{I18n.t('accessed')} " +  Time.now.strftime("%B %d, %Y") + "."
  end

  def fill_request_info
    container = container_info
    unless (container[:top_container_url].empty? || container[:top_container_url][0].blank?)&& !RequestItem::allow_nontops(@repo_info['top']['repo_code'])
      @request = RequestItem.new(container)
      @request[:request_uri] = @result['uri']
      @request[:repo_name] = @repo_info['top']['name']
      @request[:cite] = @cite
      @request[:identifier] = @result.dig('json', '_composite_identifier')
      @request[:title] = @page_title
      hier = ''
      @context.each_with_index  { |c, i| hier << c[:crumb] << '. ' unless i ==  0 || c[:uri].blank? }
      @request[:hier] = hier.strip
      note = get_note(@result['json'], 'accessrestrict')
      @request[:restrict] = note['note_text'] unless note.blank? 
      @request[:resource_id]  = @result.dig('_resolved_resource', 'json', 'uri')
      @request[:resource_name] = @result.dig('_resolved_resource', 'json', 'title')
    end
  end

# process container information
  def container_info
    info = {}
    %i(top_container_url top_container_name location_title location_url machine barcode).each  {|sym| info[sym] = [] }
    unless @result['json']['instances'].blank?
      @result['json']['instances'].each do |instance|
        hsh = container_instance(instance)
        hsh.keys.each {|sym| info[sym].push(hsh[sym] || '')}  if hsh
      end
    end
    disp = @result['json'].dig('container_disp')
    info[:top_container_name] = [disp] if info[:top_container_name].empty? && disp
    info[:top_container_url] = [@result.dig('top_container_uri_u_sstr') || ''] if  info[:top_container_url].empty?
    restricts = @result.dig('_resolved_top_container_uri_u_sstr','json','active_restrictions')
    if restricts
      restricts.each do |r|
        lar = r.dig('local_access_restriction_type')
        info[:machine].push(lar) if lar
      end
    end
    info
  end

 # returns a hash
  def container_instance(instance)
    tc = instance.dig('sub_container', 'top_container', 'ref')
    c = instance.dig('container')
    ret_hash = nil
    if tc || c
      name = ''
      title = nil
      url = nil
      barcode = nil
      if c
        (1..3).each do |i|
          type = c.dig("type_#{i}") || ''
          name << type << ' '  if type.downcase != 'unspecified'
          ind = c.dig("indicator_#{i}") || ''
          name << ind << ' '
          barcode = c.dig("barcode_#{i}")
          name << barcode << ' ' if barcode
        end
        name.strip!
        locs = c.dig('container_locations')
        if locs && !locs[0].blank?
          title = locs[0].dig('_resolved', 'title') || ''
          uri = locs[0].dig('_resolved', 'uri') || ''
        end
      end
      ret_hash =  {:top_container_name => (name.blank? ? nil : name),
        :top_container_url => tc, :location_title => title, :location_url => uri, :barcode => barcode}
    end
    ret_hash
  end

# look for a representative instance
  def get_rep_image(instances)
    rep = {}
    if instances && instances.kind_of?(Array)
      instances.each do |instance|
        unless instance['digital_object'].blank? || instance['digital_object']['_resolved'].blank? 
          it =  instance['digital_object']['_resolved']
          unless !it['publish'] || it['file_versions'].blank?
            it['file_versions'].each do |ver|
              if ver['is_representative'] && ver['xlink_show_attribute'] == 'embed' && ver['publish']
                rep['title'] = strip_mixed_content(it['title'])
                rep['uri'] = ver['file_uri']
              end
            end
          end
        end
      end
    end
    rep
  end

# digital object processing 
  def process_digital(json)
    dig = {}
    unless json['digital_object_id'].blank? ||  !json['digital_object_id'].start_with?('http')
      dig['out'] = json['digital_object_id']
    end
    dig = process_file_versions(json, dig)
    unless dig.blank?
      dig['material'] = json['digital_object_type'].blank? ? '' : '(' << json['digital_object_type'] << ')'
      dig['caption'] = CGI::escapeHTML(strip_mixed_content(json['title'])) if dig['caption'].blank? && !dig['thumb'].blank?
    end
    dig
  end

# representative digital object for an archival object
  def process_digital_instance(instances)
    dig = {}
    if instances && instances.kind_of?(Array)
      instances.each do |instance|
        unless !instance.dig('digital_object','_resolved')
          it =  instance['digital_object']['_resolved']
           unless it['file_versions'].blank?
             title = strip_mixed_content(it['title'])
             dig = process_file_versions(it, dig)
             dig['caption'] = CGI::escapeHTML(title) if dig['caption'].blank?
           end
        end
        break if !dig.blank?
      end
    end
    dig
  end

  def process_file_versions(json, dig)
    unless json['file_versions'].blank?
      json['file_versions'].each do |version|
        if version['publish'] && version['file_uri'].start_with?('http')
          unless json['html'].blank? || json['html']['note'].blank?
            dig['caption'] =  json['html']['note']['note_text']
          end
          if !version['xlink_show_attribute'].blank? && (version['xlink_show_attribute']||'') == 'embed'
            dig['thumb'] = (dig['thumb']? dig['thumb'].push(version['file_uri']) : [version['file_uri']])
            dig['represent'] = 'embed' if version['is_representative']
          elsif !version['publish'].blank? && version['publish']
             dig['represent'] = 'new'  if version['is_representative']
            dig['out'] = version['file_uri'] if version['file_uri'] != (dig['out'] || '')
          end
        elsif !version['file_uri'].start_with?('http')
          Rails.logger.debug("****BAD URI? #{version['file_uri']}")
        end
      end
    end
    dig
  end
end
