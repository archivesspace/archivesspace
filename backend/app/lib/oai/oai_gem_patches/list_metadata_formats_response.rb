module OAI::Provider::Response
  class ListMetadataFormats < RecordResponse

    def to_xml
      # Get a list of all the formats the provider understands.
      formats = provider.formats.values

      # if it's a doc-specific request
      if options.include?(:identifier)
        uri = extract_identifier(options[:identifier])

        jsonmodel_type = JSONModel.parse_reference(uri).fetch(:type) { raise OAI::IdException.new }

        # Only select formats where this type is supported
        formats.select! {|f|
          format = ArchivesSpaceOAIRepository.available_record_types.fetch(f.prefix)
          format.record_types.any?{|jsonmodel_clz|
            jsonmodel_clz.my_jsonmodel.record_type == jsonmodel_type
          }
        }
      end

      response do |r|
        r.ListMetadataFormats do
          formats.each do |format|
            r.metadataFormat do
              r.metadataPrefix format.prefix
              r.schema format.schema
              r.metadataNamespace format.namespace
            end
          end
        end
      end
    end

  end
end
