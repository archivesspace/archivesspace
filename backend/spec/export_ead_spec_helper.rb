module ExportEADSpecHelper



  #######################################################################
  # FIXTURES

  def load_export_fixtures
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

    # this tests that note order is preserved, even when it's a
    # text.text.list.text setup.
    @mixed_subnotes_tracer = build("json_note_multipart", {
                        :type => 'bioghist',
                        :publish => true,
                       :persistent_id => "mixed_subnotes_tracter",
                       :subnotes => [build(:json_note_text, { :publish => true, 
                                                              :content => "note_text - The ship set ground on the shore of this uncharted desert isle"} ), 
                                     build(:json_note_text, { :publish => true, 
                                                                :content => "note_text - With:"}),
                                    build(:json_note_definedlist,{  :publish => true, :title => "note_definedlist",
                                                                      :items => [
                                                                        {:label => "First Mate", :value => "Gilligan" },
                                                                        {:label => "Captain",:value => "The Skipper"},
                                                                        {:label => "Etc.", :value => "The Professor and Mary Ann" }
                                                                      ] 
                                    }),
                                    build(:json_note_text,{   :content => "note_text - Here on Gillgian's Island", :publish => true}) ]                                         
    })


    resource = create(:json_resource,  :linked_agents => build_linked_agents(@agents),
                       :notes => build_archival_object_notes(100) + [@mixed_subnotes_tracer],
                       :subjects => @subjects.map{|ref, s| {:ref => ref}},
                       :instances => instances,
                       :finding_aid_status => %w(completed in_progress under_revision unprocessed).sample,
                       :finding_aid_filing_title => "this is a filing title",
                       :finding_aid_series_statement => "here is the series statement"
                       )

    @resource = JSONModel(:resource).find(resource.id)

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

      a = JSONModel(:archival_object).find(a.id)

      @archival_objects[a.uri] = a
    }
  end


  def mt(*args)
    raise "XML document not loaded" unless @doc && @doc_nsless
    doc_to_test = args[1].match(/\/xmlns:[\w]+/) ? @doc : @doc_nsless
    test_mapping_template(doc_to_test, *args)
  end


  def test_mapping_template(doc, data, path, trib=nil)
    
    case path.slice(0) 
    when '/' 
      path
    when '.'
      path.slice!(0..1) 
    else 
      path.prepend("/#{doc.root.name}/")
    end

    node = doc.at(path)
    val = nil

    if data
      doc.should have_node(path)
      if trib.nil?
        node.should have_inner_text(data)
      elsif trib == :markup 
        node.should have_inner_markup(data)
      else
        node.should have_attribute(trib, data)
      end
    elsif node && trib
      node.should_not have_attribute(trib)
    end
  end


  def get_xml_doc(uri)
    response = get(uri)
    doc = Nokogiri::XML::Document.parse(response.body)

    doc
  end

  def build_archival_object_notes(max = 5)
    note_types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial arrangement fileplan accessrestrict abstract scopecontent prefercite acqinfo bibliography index altformavail originalsloc userestrict legalstatus relatedmaterial custodhist appraisal accruals bioghist)
    notes = []
    brake = 0
    while !(note_types - notes.map {|note| note['type']}).empty? && brake < max do
      notes << build("json_note_#{['singlepart', 'multipart', 'multipart_gone_wilde', 'index', 'bibliography'].sample}".intern, {
                       :publish => true,
                       :persistent_id => [nil, generate(:alphanumstr)].sample
                     })
      brake += 1
    end

    notes
  end


  def build_linked_agents(agents)
    agents = agents.map{|ref, a| {
        :ref => ref,
        :role => (ref[-1].to_i % 2 == 0 ? 'creator' : 'subject'),
        :terms => [build(:json_term), build(:json_term)],
        :relator => (ref[-1].to_i % 4 == 0 ? generate(:relator) : nil)
      }
    }
    # let's makes sure there's one agent a creator without and terms.
    agents.find { |a| a[:role] == "creator" }[:terms] = []
    agents.shuffle

  end


  def translate(enum_path, value)
    enum_path << "." unless enum_path =~ /\.$/
    I18n.t("#{enum_path}#{value}", :default => value)
  end


  #######################################################################




end
