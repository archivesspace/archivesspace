module OAI::Provider::Response

  class Identify < Base

    def to_xml
      response do |r|
        r.Identify do
          r.repositoryName provider.name
          r.baseURL provider.url
          r.protocolVersion 2.0
          if provider.email and provider.email.respond_to?(:each)
            provider.email.each { |address| r.adminEmail address }
          else
            r.adminEmail provider.email.to_s
          end
          r.earliestDatestamp Time.parse(provider.model.earliest.to_s).utc.xmlschema
          r.deletedRecord provider.delete_support.to_s
          r.granularity provider.granularity
          r.description do
            r.tag! 'oai-identifier', 'xmlns' => 'http://www.openarchives.org/OAI/2.0/oai-identifier', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/oai-identifier http://www.openarchives.org/OAI/2.0/oai-identifier.xsd' do
              r.scheme 'oai'
              r.repositoryIdentifier provider.prefix.gsub(/oai:/, '')
              r.delimiter ':'
              # ASpace uses '/' to separate the prefix and identifier
              r.sampleIdentifier "#{provider.prefix}/#{provider.identifier}"
            end
          end
          if provider.description
            r.target! << provider.description
          end
        end

      end
    end

  end

end
