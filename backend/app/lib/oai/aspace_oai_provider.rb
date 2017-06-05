require 'oai'

require_relative 'aspace_oai_repository'
require_relative 'aspace_oai_record'
require_relative 'ead_format'
require_relative 'dc_terms_format'
require_relative 'marc_format'
require_relative 'mods_format'


class ArchivesSpaceOaiProvider < OAI::Provider::Base
  repository_name AppConfig[:oai_repository_name]
  repository_url AppConfig[:oai_proxy_url]
  record_prefix AppConfig[:oai_record_prefix]
  admin_email AppConfig[:oai_admin_email]

  deletion_support OAI::Const::Delete::PERSISTENT

  source_model ArchivesSpaceOAIRepository.new

  register_format EADFormat.instance
  register_format DCTermsFormat.instance
  register_format MARCFormat.instance
  register_format MODSFormat.instance
end

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
