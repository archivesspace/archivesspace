# Needed to give our resumption token a chance to get in first.  Otherwise we
# get the default 'oai' one.
module OAI::Provider::Response
  class RecordResponse < Base
    def requested_format
      format =
        if options[:metadata_prefix]
          options[:metadata_prefix]
        elsif options[:resumption_token]
          ArchivesSpaceResumptionToken.extract_format(options[:resumption_token])
        end

      raise OAI::FormatException.new unless provider.format_supported?(format)

      format
    end
  end
end
