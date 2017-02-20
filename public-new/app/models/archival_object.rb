class ArchivalObject < Record

  attr_reader :cite

  def initialize(*args)
    super

    @cite = parse_cite_string
  end

  def finding_aid
    # as this shares the same template as resources,
    # be clear that this object doesn't have a finding aid
    nil
  end

  private

  def parse_cite_string
    cite = note('prefercite')
    unless cite.blank?
      cite = strip_mixed_content(cite['note_text'])
    else
      cite = strip_mixed_content(display_string) + "."
      ttl = resolved_resource.dig('title')
      cite += " #{strip_mixed_content(ttl)}." unless !ttl
      cite += " #{ repository_information['top']['name']}." unless !repository_information.dig('top','name')
    end

    "#{cite}   #{cite_url_and_timestamp}."
  end
end