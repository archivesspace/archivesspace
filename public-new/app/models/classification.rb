class Classification < Record

  attr_reader :linked_records, :creator

  def initialize(*args)
    super

    @linked_records = parse_linked_records
    @creator = parse_creator
  end

  def description
    json['description'] || ''
  end

  private

  def parse_linked_records
    records = []

    ASUtils.wrap(json['linked_records']).each do |rec|
      if  rec['_resolved'].present? && rec['_resolved']['publish']
        records << record_from_resolved_json(rec['_resolved'])
      end
    end

    records
  end

  def parse_full_title
     "#{ASUtils.wrap(json['path_from_root']).collect{|c| c['identifier']}.join('/')} #{json['title']}"
  end

  def parse_identifier
    json['identifier']
  end

  def parse_creator
    ASUtils.wrap(raw['agent_uris']).collect{|uri|
      if raw['_resolved_agent_uris']
        raw['_resolved_agent_uris'][uri].first
      end
    }.compact.select{|agent|
      agent['publish']
    }.map {|agent|
      record_from_resolved_json(ASUtils.json_parse(agent['json']))
    }.first # there's only ever one... for now...
  end

end