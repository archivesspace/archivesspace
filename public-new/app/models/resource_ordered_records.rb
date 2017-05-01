class ResourceOrderedRecords < Record

  attr_reader :entries

  Entry = Struct.new(:uri, :display_string, :depth)

  def initialize(*args)
    super

    @entries = Array(json['uris']).map {|entry| Entry.new(entry.fetch('ref'),
                                                          entry.fetch('display_string'),
                                                          entry.fetch('depth'))}
  end
end
