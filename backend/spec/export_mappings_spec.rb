require 'nokogiri'
require 'spec_helper'

#################################################
# It is not recommended that this specification #
# be developed further. Going forward, use or   #
# create a specification for whatever export    #
# format you are working on, e.g.,              #
# export_mods_spec.rb                           #
#################################################


describe 'Export Mappings' do

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



    resource = create(:json_resource,  :linked_agents => build_linked_agents(@agents),
                       :notes => build_archival_object_notes(100),
                       :subjects => @subjects.map{|ref, s| {:ref => ref}},
                       :instances => instances,
                       :finding_aid_status => %w(completed in_progress under_revision unprocessed).sample
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
      notes << build("json_note_#{['singlepart', 'multipart', 'index', 'bibliography'].sample}".intern, {
                       :publish => true,
                       :persistent_id => [nil, generate(:alphanumstr)].sample
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


  def translate(enum_path, value)
    enum_path << "." unless enum_path =~ /\.$/
    I18n.t("#{enum_path}#{value}", :default => value)
  end

  describe "MARC export mappings" do

    # Marc export helpers

    # typical mapping of source codes to marc @ind2 attribute
    def source_to_code(source)
      code =  case source
              when 'naf', 'lcsh'; 0
              when 'lcshac'; 1
              when 'mesh'; 2
              when 'nal'; 3
              when nil; 4
              when 'cash'; 5
              when 'rvm'; 6
              else; 7
              end
      code.to_s
    end

    # typical marc subfield codes contingent upon term type
    def term_type_code(term)
      case term['term_type']
      when 'uniform_title'; 't'
      when 'genre_form', 'style_period'; 'v'
      when 'topical', 'cultural_context'; 'x'
      when 'temporal'; 'y'
      when 'geographic'; 'z'
      end
    end


    def test_person_name(df, name)
      name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}\
        .join(name['name_order'] == 'direct' ? ' ' : ', ')

      agent_test_template(df, {
                            'a' => name_string,
                            'b' => name['number'],
                            'c' => %w(prefix title suffix).map{|p| name[p]}.compact.join(', '),
                            'd' => name['dates'],
                            'q' => name['fuller_form']
                          })
    end


    def test_family_name(df, name)
      agent_test_template(df, {
                            'a' => name['family_name'],
                            'c' => name['prefix'],
                            'd' => name['dates'],
                          })
    end


    def test_corporate_name(df, name)
      agent_test_template(df, {
                            'a' => name['primary_name'],
                            'b' => [name['subordinate_name_1'], name['subordinate_name_2']],
                            'n' => name['number'],
                          })
    end


    def agent_test_template(df, code_hash)
      code_hash.each do |code, value|
        test_values = value.is_a?(Array) ? value : [value]
        test_values.each do |tv|
          next if tv.nil? || tv.empty?
          df.should have_node("subfield[@code='#{code}'][text()='#{tv}']")
        end
      end
    end


    def note_test(note_types, dfcodes, sfcode, filters = {})
      raise "Missing test instance variable @resource" unless @resource
      raise "Missing test instance variable @doc" unless @doc

      notes = @resource.notes.select{|n| note_types.include?(n['type'])}
      filters.each do |k, v|
        notes.reject! {|n| n[k] != v }
      end

      return unless notes.count > 0
      xml_content = @doc.df(*dfcodes).sf_t(sfcode)
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    #######################################################################


    # shortcut xpath method
    module SloppyXpath
      def sxp(path)
        ns_path = path.split('/').map {|p| (p.empty? || p =~ /\w+:/) ? p : "xmlns:#{p}"}.join('/')
        self.xpath(ns_path)
      end
    end


    class Nokogiri::XML::Node
      include SloppyXpath
    end

    class Nokogiri::XML::NodeSet
      include SloppyXpath
    end


    def note_test(note_types, dfcodes, sfcode, filters = {})
      raise "Missing test instance variable @resource" unless @resource
      raise "Missing test instance variable @doc" unless @doc

      notes = @resource.notes.select{|n| note_types.include?(n['type'])}
      filters.each do |k, v|
        notes.reject! {|n| n[k] != v }
      end

      return unless notes.count > 0
      xml_content = @doc.df(*dfcodes).sf_t(sfcode)
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end


    before(:all) do
      as_test_user("admin") do
        DB.open(true) do
          load_export_fixtures
          @doc = get_xml_doc("/repositories/#{$repo_id}/resources/marc21/#{@resource.id}.xml")
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

          raise Sequel::Rollback
        end
      end
    end

    it "provides default values for record/leader: 00000np$ a2200000 u 4500" do
      @doc.sxp("//record/leader").inner_text.should match(/00000np.\sa2200000\su\s4500/)
    end


    it "maps resource.level to record/leader[7]" do
      @doc.sxp("//record/leader").inner_text[7].should eq(@resource.level == 'item' ? 'm' : 'c')
    end


    it "maps resource record mtime to record/controlfield[@tag='008']/text()[0..5]" do
      @doc.sxp("//record/controlfield").inner_text[0..5].should match(/\d{6}/)
    end


    it "sets record/controlfield[@tag='008']/text()[6] according to resource.level" do
      whatitshouldbe = (@resource.level == 'item' && @resource.dates[0]['date_type'] == 'single' ? 's' : 'i')
      @doc.sxp("//record/controlfield").inner_text[6].should eq(whatitshouldbe)
    end


    it "sets record/controlfield[@tag='008']/text()[7..10] with resource.dates[0]['begin']" do
      whatitshouldbe = @resource.dates[0]['begin'] ? @resource.dates[0]['begin'][0..3] : "    "
      @doc.sxp("//record/controlfield").inner_text[7..10].should eq(whatitshouldbe)
    end


    it "sets record/controlfield[@tag='008']/text()[11..14] with resource.dates[0]['end']" do
      unless (@resource.level == 'item' && @resource.dates[0]['date_type'] == 'single')
        whatitshouldbe = @resource.dates[0]['end'] ? @resource.dates[0]['end'][0..3] : "    "
        @doc.sxp("//record/controlfield").inner_text[11..14].should eq(whatitshouldbe)
      end
    end


    it "sets record/controlfield[@tag='008']/text()[15..16] with 'xx'" do
      @doc.sxp("//record/controlfield").inner_text[15..16].should eq('xx')
    end


    it "sets record/controlfield[@tag='008']/text()[35..37] with resource.language" do
      @doc.sxp("//record/controlfield").inner_text[35..37].should eq(@resource.language)
    end


    it "sets record/controlfield[@tag='008']/text()[38..39] with ' d'" do
      @doc.sxp("//record/controlfield").inner_text[38..39].should eq(' d')
    end


    it "maps repository.org_code to datafield[@tag='040' and @ind1=' ' and @ind2=' '] subfields a and c" do
      org_code = JSONModel(:repository).find($repo_id).org_code
      @doc.df('040', ' ', ' ').sf_t('a').should eq(org_code)
      @doc.df('040', ' ', ' ').sf_t('c').should eq(org_code)
    end


    it "maps resource.finding_aid_description_rules to df[@tag='040' and @ind1=' ' and @ind2=' ']/sf[@code='e']" do
      @doc.df('040', ' ', ' ').sf_t('e').should eq(@resource.finding_aid_description_rules || '')
    end


    it "maps resource.language to df[@tag='041' and @ind1='0' and @ind2=' ']/sf[@code='a']" do
      @doc.df('041', '0', ' ').sf_t('a').should eq(@resource.language)
    end


    it "maps resource.id_\\d to df[@tag='099' and @ind1=' ' and @ind2=' ']/sf[@code='a']" do
      @doc.df('099', ' ', ' ').sf_t('a').should eq((0..3).map {|i|@resource.send("id_#{i}") }.compact.join('.'))
    end


    it "maps the first creator to df[@tag='100'] or df[@tag='110']" do
      clink = @resource.linked_agents.find{|l| l['role'] == 'creator'}
      creator = @agents[clink['ref']]
      cname = creator['names'][0]
      df = nil
      case creator.agent_type
      when 'agent_corporate_entity'
        df = @doc.df('110', '2', ' ')
        df.count.should eq(1)
        test_corporate_name(df, cname)
      when 'agent_family'
        df = @doc.df('100', '3', ' ')
        df.count.should eq(1)
        test_family_name(df, cname)
      when 'agent_person'
        inverted = cname['name_order'] == 'direct' ? '0' : '1'
        df = @doc.df('100', inverted, ' ')
        df.count.should eq(1)
        test_person_name(df, cname)
      end
      df.sf_t('d').should eq(cname['dates'])
      df.sf_t('g').should eq(cname['qualifier'])
      if clink['relator']
        df.sf_t('4').should eq(clink['relator'])
      else
        df.sf_t('e').should eq('creator')
      end
    end


    it "maps notes of type (odd|dimensions|physdesc|materialspec|physloc|phystech|physfacet|processinfo|separatedmaterial) to df 500, sf a" do
      xml_content = @doc.df('500', ' ', ' ').sf_t('a')
      types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial)
      notes = @resource.notes.select{|n| types.include?(n['type'])}
      (notes.count > 0).should be_true
      notes.each do |note|
        prefix = case note['type']
        when 'odd'; nil
        when 'dimensions'; "Dimensions"
        when 'physdesc'; "Physical Description note"
        when 'materialspec'; "Material Specific Details"
        when 'physloc'; "Location of resource"
        when 'phystech'; "Physical Characteristics / Technical Requirements"
        when 'physfacet'; "Physical Facet"
        when 'processinfo'; "Processing Information"
        when 'separatedmaterial'; "Materials Separated from the Resource"
        end
        string = prefix ? "#{prefix}: " : ""
        string += note_content(note)
        xml_content.should include(string)
      end
    end


    it "maps notes of type 'accessrestrict' to df 506, sf a" do
      note_test(%w(accessrestrict), ['506', ' ', ' '], 'a')
    end


    it "maps notes of type 'abstract' to df 520 ('3', ' '), sf a" do
      note_test(%w(abstract), ['520', '3', ' '], 'a')
    end


    it "maps notes of type 'scopecontent' to df 520 ('2', ' '), sf a" do
      note_test(%w(scopecontent), ['520', '2', ' '], 'a')
    end


    it "maps notes of type 'prefercite' to df 534 ('8', ' '), sf a" do
      note_test(%w(prefercite), ['534', '8', ' '], 'a')
    end


    it "maps notes of type 'altformavail' to df 535 ('2', ' '), sf a" do
      note_test(%w(altformavail), ['535', '2', ' '], 'a')
    end


    it "maps notes of type 'originalsloc' to df 535 ('1', ' '), sf a" do
      note_test(%w(originalsloc), ['535', '1', ' '], 'a')
    end


    it "maps notes of type 'userestrict' | 'legalstatus' to df 540 (' ', ' '), sf a" do
      note_test(%w(userestrict legalstatus), ['540', ' ', ' '], 'a')
    end


    it "maps public notes of type 'acqinfo' to df 541 ('1', ' '), sf a" do
      note_test(%w(acqinfo), ['541', '1', ' '], 'a', {'publish' => true})
    end


    it "maps private notes of type 'acqinfo' to df 541 ('0', ' '), sf a" do
      note_test(%w(acqinfo), ['541', '0', ' '], 'a', {'publish' => false})
    end


    it "maps notes of type 'relatedmaterial' to df 544 (' ', ' '), sf a" do
      note_test(%w(relatedmaterial), ['544', ' ', ' '], 'a')
    end


    it "maps notes of type 'bioghist' to df 545 (' ', ' '), sf a" do
      note_test(%w(bioghist), ['545', ' ', ' '], 'a')
    end


    it "maps notes of type 'langmaterial' to df 546 (' ', ' '), sf a" do
      note_test(%w(langmaterial), ['546', ' ', ' '], 'a')
    end


    it "maps resource.ead_location to df 555 (' ', ' '), sf a" do
      df = @doc.df('555', ' ', ' ')
      df.sf_t('u').should eq(@resource.ead_location)
      df.sf_t('a').should eq("Finding aid online:")
    end


    it "maps public notes of type 'custodhist' to df 561 ('1', ' '), sf a" do
      note_test(%w(custodhist), ['561', '1', ' '], 'a', {'publish' => true})
    end


    it "maps private notes of type 'custodhist' to df 561 ('0', ' '), sf a" do
      note_test(%w(custodhist), ['561', '0', ' '], 'a', {'publish' => false})
    end


    it "maps public notes of type 'appraisal' to df 583 ('1', ' '), sf a" do
      note_test(%w(appraisal), ['583', '1', ' '], 'a', {'publish' => true})
    end


    it "maps private notes of type 'appraisal' to df 583 ('0', ' '), sf a" do
      note_test(%w(appraisal), ['583', '0', ' '], 'a', {'publish' => false})
    end


    it "maps notes of type 'accruals' to df 584 (' ', ' '), sf a" do
      note_test(%w(accruals), ['584', ' ', ' '], 'a')
    end


    it "maps agents with 'subject' role to field 600|610" do
      subjects = @resource.linked_agents.select{|l| l['role'] == 'subject'}.map{|s| @agents[s['ref']]}

      subjects.each do |subject|
        relator = @resource.linked_agents.find{|l| l['ref'] == subject.uri}['relator']
        terms = @resource.linked_agents.find{|l| l['ref'] == subject.uri}['terms']
        name = subject.names[0]
        df = nil

        ind2 =  source_to_code(name['source'])

        case subject['agent_type']
        when 'agent_person'
          ind1 = name['name_order'] == 'direct' ? '0' : '1'
          df = @doc.df('600', ind1, ind2)
          test_person_name(df, name)

        when 'agent_family'
          df = @doc.df('600', '3', ind2)
          test_family_name(df, name)

        when 'agent_corporate_entity'
          df = @doc.df('610', '2', ind2)
          test_corporate_name(df, name)
          # Specified, but not implemented in ASpace data model
          # terms.each do |term|
          #   code = term_type_code(term)
          #   df.sf_t(code).should include(term['term'])
          # end
        end

        df.sf_t('g').should include(name['qualifier'])

        if relator
          df.sf_t('4').should include(relator)
        elsif ind2 == 7
          df.sf_t('2').should include(subject['source'])
        end
      end
    end


    it "maps subject.terms[0] to df 630-656 (' ', $)" do
      @resource.subjects.each do |link|
        subject = @subjects[link['ref']]
        term = subject['terms'][0]
        terms = subject['terms'][1..-1]
        code, ind2 =  case term['term_type']
        when 'uniform_title'
          ['630', source_to_code(subject['source'])]
        when 'temporal'
          ['648', source_to_code(subject['source'])]
        when 'topical'
          ['650', source_to_code(subject['source'])]
        when 'geographic', 'cultural_context'
          ['651', source_to_code(subject['source'])]
        when 'genre_form', 'style_period'
          ['655', source_to_code(subject['source'])]
        when 'occupation'
          ['656', '7']
        when 'function'
          ['656', '7']
        end

        df = @doc.df(code, ' ', ind2)
        df.sf_t('a').should include(term['term'])

        terms.each do |t|
          code = term_type_code(t)
          df.sf_t(code).should include(t['term'])
        end

        if ind2 == '7'
          df.sf_t('2').should include(subject['source'])
        end

      end
    end


    it "maps secondary agents with 'creator' or 'source' role to df 700|710" do
      creators = @resource.linked_agents.select{|l| l['role'] == 'creator' || l['role'] == 'source'}[1..-1]

      creators.each do |link|
        creator = @agents[link['ref']]
        relator = link['relator']
        role = link['role']
        name = creator.names[0]
        df = nil

        case creator['agent_type']
        when 'agent_person'
          ind1 = name['name_order'] == 'direct' ? '0' : '1'
          name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}\
            .join(name['name_order'] == 'direct' ? ' ' : ', ')
          df = @doc.df('700', ind1, ' ')
          test_person_name(df, name)

        when 'agent_family'
          df = @doc.df('700', '3', ' ')
          test_family_name(df, name)

        when 'agent_corporate_entity'
          df = @doc.df('710', '2', ' ')
          test_corporate_name(df, name)
        end

        df.sf_t('g').should include(name['qualifier'])
        if relator
          df.sf_t('4').should include(relator)
        elsif role == 'source'
          df.sf_t('e').should include('former owner')
        else
          df.sf_t('e').should include('creator')
        end

      end
    end


    it "maps repository identifier data to df 852" do
      repo = JSONModel(:repository).find($repo_id)

      df = @doc.df('852', ' ', ' ')
      df.sf_t('a').should include(repo.org_code)
      df.sf_t('b').should eq(repo.name)
      df.sf_t('c').should eq((0..3).map{|i| @resource.send("id_#{i}")}.compact.join('.'))
    end


    it "maps EAD location information to df 856" do
      df = @doc.df('856', '4', '2')
      df.sf_t('z').should eq('Finding aid online:')
      df.sf_t('u').should eq(@resource.ead_location)
    end

  end
end
