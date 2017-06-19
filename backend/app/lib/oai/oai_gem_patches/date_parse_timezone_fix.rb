class OAI::Provider::Response::Base

  def parse_date(value)
    return value if value.respond_to?(:strftime)

    Date.parse(value) # This will raise an exception for badly formatted dates

    # ArchivesSpace fix: don't parse a simple date into the wrong timezone!
    #
    # The OAI gem helpfully parses the incoming time string, but appears to
    # incorrectly adjust it relative to the local timezone.  For example, I
    # give a date of '2017-05-28' meaning "the 28th of May, 2017 UTC", and it
    # parses that into the 27th of May, 1pm UTC (my timezone is +11:00).
    #
    parsed = Time.parse(value)

    if parsed.utc_offset != 0
      # We want our timestamp as UTC!
      offset = parsed.utc_offset
      parsed.utc + offset
    else
      parsed
    end
  rescue
    raise OAI::ArgumentException.new, "unparsable date: '#{value}'"
  end
end
