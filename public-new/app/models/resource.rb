class Resource < Record

  attr_reader :digital_instances, :finding_aid

  def initialize(*args)
    super

    @digital_instances = parse_digital_instance
    @finding_aid = parse_finding_aid
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
end