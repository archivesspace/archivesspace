module ExportSpecHelpers

  def load_marc_doc
    raise "Fixtures <repo> and <resource> not loaded" unless @repo && @resource
    @doc = get_xml_doc("/repositories/#{@repo.id}/resources/marc21/#{@resource.id}.xml")

    @doc.instance_eval do
      def df(tag, ind1=nil, ind2=nil)
        selector ="@tag='#{tag}'"
        selector += " and @ind1='#{ind1}'" if ind1
        selector += " and @ind2='#{ind2}'" if ind2
        datafields = self.xpath("//xmlns:datafield[#{selector}]")
        datafields.instance_eval do
          def sf(code)
            self.xpath("xmlns:subfield[@code='#{code}']")
          end
          def sf_t(code)
            sf(code).inner_text
          end
        end

        datafields
      end
    end
  end


  def load_ead_doc
    raise "Fixtures <repo> and/or <resource> not loaded" unless @repo && @resource
    @doc = get_xml_doc("/repositories/#{@repo.id}/resource_descriptions/#{@resource.id}.xml")
    raise "Problem loading EAD document: see server log" unless @doc && @doc.root && @doc.root.name == 'ead'
    @doc_nsless = Nokogiri::XML::Document.parse(@doc.to_xml)
    @doc_nsless.remove_namespaces!
  end


  def doc(use_namespaces = false)
    use_namespaces ? @doc : @doc_nsless
  end


  def archival_object(index)
    @archival_objects.values[index]
  end


  def hijack_enum_source
    @old_enum_source = JSONModel.init_args[:enum_source]
    JSONModel.init_args[:enum_source] = JSONModel::Client::EnumSource.new
  end


  def giveback_enum_source
    return false unless @old_enum_source
    JSONModel.init_args[:enum_source] = @old_enum_source
  end


  def get_xml_doc(uri)
    uri = URI.parse("#{$backend_url}#{uri}")
    response = JSONModel::HTTP.get_response(uri)
    doc = Nokogiri::XML::Document.parse(response.body)

    doc
  end


  def mt(*args)
    raise "XML document not loaded" unless @doc && @doc_nsless
    doc_to_test = args[1].match(/\/xmlns:[\w]+/) ? @doc : @doc_nsless
    test_mapping_template(doc_to_test, *args)
  end


  def test_mapping_template(doc, data, path, trib=nil)
    unless path.slice(0) == '/'
      path.prepend("/#{doc.root.name}/")
    end

    node = doc.at(path)
    val = nil

    if data
      doc.should have_node(path)
      if trib.nil?
        node.should have_inner_text(data)
      else
        node.should have_attribute(trib, data)
      end
    elsif node && trib
      node.should_not have_attribute(trib)
    end
  end
end
