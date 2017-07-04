class ArchivesSpaceResumptionToken

  PRODUCING_RECORDS_STATE = 'producing_records'
  PRODUCING_DELETES_STATE = 'producing_deletes'

  def initialize(options, available_record_types)
    @options = Hash[options.map {|k, v| [k.to_s, v]}]

    @options['state'] ||= PRODUCING_RECORDS_STATE
    @options['last_delete_id'] ||= 0

    unless @options.has_key?('remaining_types')
      types_for_format = available_record_types.fetch(format) { raise OAI::FormatException.new }
      @options['remaining_types'] = Hash[types_for_format.record_types.map {|type| [type.to_s, 0]}]
    end
  end

  def self.extract_format(token)
    self.parse(token, {}).format
  end

  def state
    @options.fetch('state')
  end

  def start_deletes!
    @options['state'] = PRODUCING_DELETES_STATE
  end

  def last_delete_id
    @options.fetch('last_delete_id')
  end

  def last_delete_id=(value)
    @options['last_delete_id'] = value
  end

  def format
    @options.fetch('metadata_prefix')
  end

  def set
    @options.fetch('set', nil)
  end

  def from
    @options.fetch('from', nil)
  end

  def until
    @options.fetch('until', nil)
  end

  def remaining_types
    @options.fetch('remaining_types').sort_by {|type, _| type}
  end

  def update_depleted(types)
    types.each do |depleted_type|
      @options['remaining_types'].delete(depleted_type)
    end

    self
  end

  def any_records_left?
    !remaining_types.empty?
  end

  def set_last_seen(oai_record)
    return self unless oai_record

    aspace_record = oai_record.sequel_record

    # We've already depleted this record type
    return self unless @options['remaining_types'].has_key?(aspace_record.class.to_s)

    @options['remaining_types'][aspace_record.class.to_s] = aspace_record.id

    self
  end

  def self.parse(token, available_record_types)
    new(ASUtils.json_parse(Base64::urlsafe_decode64(token)), available_record_types)
  end

  def serialize
    issue_time = (Time.now.to_f * 1000).to_i

    Base64::urlsafe_encode64(@options.merge('issue_time' => issue_time).to_json)
  end

  def to_xml
    xml = Builder::XmlMarkup.new
    xml.resumptionToken(self.serialize)

    xml.target!
  end

end
