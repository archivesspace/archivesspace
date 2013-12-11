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


  def load_repo
    @repo_agent = build(:json_agent_corporate_entity)
    rwa = create(:json_repo_with_agent,:agent_representation => @repo_agent)
    @repo = JSONModel(:repository).find(rwa.id)
    JSONModel.set_repository(@repo.id)
  end


  def load_export_fixtures
    raise "Run 'load_repo' before loading fixtures" unless @repo
    @agents = {}
    5.times {
      a = create([:json_agent_person, :json_agent_corporate_entity, :json_agent_family].sample)
      @agents[a.uri] = a
    }

    @subjects = {}
    5.times {
     s = create(:json_subject)
     @subjects[s.uri] = s
    }

    @digital_objects = {}
    5.times {
      d = create(:json_digital_object)
      @digital_objects[d.uri] = d
    }

    instances = []
    @digital_objects.keys.each do |ref|
      instances << build(:json_instance, :digital_object => {:ref => ref})
    end

    #throw in a couple non-digital instances
    rand(3).times { instances << build(:json_instance) }



    @resource = create(:json_resource,  :linked_agents => build_linked_agents(@agents),
                                        :notes => build_archival_object_notes(100),
                                        :subjects => @subjects.map{|ref, s| {:ref => ref}},
                                        :instances => instances,
                                        :finding_aid_status => %w(completed in_progress under_revision unprocessed).sample
                      )

    @archival_objects = {}

    10.times {
      parent = [true, false].sample ? @archival_objects.keys[rand(@archival_objects.keys.length)] : nil
      a = create(:json_archival_object_normal,  :resource => {:ref => @resource.uri},
                                                :parent => parent ? {:ref => parent} : nil,
                                                :notes => build_archival_object_notes(5),
                                                :linked_agents => build_linked_agents(@agents),
                                                :instances => [build(:json_instance_digital), build(:json_instance)],
                                                :subjects => @subjects.map{|ref, s| {:ref => ref}}.shuffle


                )

      @archival_objects[a.uri] = a
    }
  end


  def build_archival_object_notes(max = 5)
    note_types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial \
                    arrangement fileplan accessrestrict abstract scopecontent prefercite acqinfo bibliography index \
                    altformavail originalsloc userestrict legalstatus relatedmaterial custodhist appraisal accruals \
                    bioghist)
    notes = []
    brake = 0
    while !(note_types - notes.map {|note| note['type']}).empty? && brake < max do
      notes << build("json_note_#{['singlepart', 'multipart', 'index', 'bibliography'].sample}".intern, {
                       # TODO: restore this(??) --v 
                       # :publish => [true, false].sample,
                       :publish => true,
                       :persistent_id => [nil, generate(:whatever)].sample
                     })
      brake += 1
    end

    notes
  end


  def build_linked_agents(agents)
    agents.map{|ref, a| {
                          :ref => ref,
                          :role => (ref[-1].to_i % 2 == 0 ? 'creator' : 'subject'),
                          :terms => [build(:json_term), build(:json_term)],
                          :relator => (ref[-1].to_i % 4 == 0 ? generate(:relator) : nil)
                        }
              }.shuffle
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
