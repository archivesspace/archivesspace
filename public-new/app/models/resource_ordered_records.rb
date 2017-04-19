class ResourceOrderedRecords < Record

  attr_reader :uris

  def initialize(*args)
    super

    @uris = parse_uris
  end

  private

  def parse_uris
    Array(json['uris']).map {|uri| uri['ref']}
  end
end
