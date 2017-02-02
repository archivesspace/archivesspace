class Classification < Record

  attr_reader :linked_records

  def initialize(*args)
    super

    @linked_records = parse_linked_records
  end

  private

  def parse_linked_records
    records = []

    json['linked_records'].each do |rec|
      if  rec['_resolved'].present? && rec['_resolved']['publish']
        records << Record.from_resolved_json(rec['_resolved'])
      end
    end

    records
  end

end