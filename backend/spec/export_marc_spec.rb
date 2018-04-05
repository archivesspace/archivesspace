require_relative 'export_spec_helper'

describe 'MARC Export' do

  before(:all) do
    $old_repo_id = $repo_id
    @repo = create(:json_repo)
    $repo_id = @repo.id

    JSONModel.set_repository($repo_id)
  end


  after(:all) do
    $repo_id = $old_repo_id
    JSONModel.set_repository($repo_id)
  end


  def note_test(resource, marc, note_types, dfcodes, sfcode, filters = {})

    notes = resource.notes.select{|n| note_types.include?(n['type'])}
    filters.each do |k, v|
      notes.reject! {|n| n[k] != v }
    end

    return unless notes.count > 0
    xml_content = marc.df(*dfcodes).sf_t(sfcode)
    xml_content.should_not be_empty
    notes.map{|n| note_content(n)}.join('').should eq(xml_content)
  end


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

 describe "root node content" do
    before(:each) do
      @marc = get_marc(create(:json_resource))      
      @xml = @marc.to_xml
    end


    it "root node should have marc namespace" do
      expect(@xml).to match(/<marc:collection/)
      expect(@xml).to match(/<\/marc:collection>/)
    end

    it "root node should have xmlns:marc defined" do
      expect(@xml).to match(/<marc:collection.*xmlns:marc="http:\/\/www.loc.gov\/MARC21\/slim"/)

    end

    it "root node should have xmlns:xsi defined" do
      expect(@xml).to match(/<marc:collection.*xmlns:xsi="http:\/\/www.w3.org\/2001\/XMLSchema-instance"/)
    end

    it "root node should have xsi:schemaLocation defined" do
      expect(@xml).to match(/<marc:collection.*xsi:schemaLocation="http:\/\/www.loc.gov\/standards\/marcxml\/schema\/MARC21slim.xsd http:\/\/www.loc.gov\/MARC21\/slim"/)
    end
  end  

describe "datafield element order" do
  before(:each) do
    @marc = get_marc(create(:json_resource))      
    @xml = @marc.to_xml
  end
    
  it "should generate XML with the datafield tags in numerical order" do
    datafield_element_count = @marc.xpath("//marc:record/marc:datafield").length
    last_tag = 0

    # loop through all tags. make sure that datafield[@tag] is a smaller number than the preceeding one.
    0.upto(datafield_element_count - 1) do |i|
      this_tag = @marc.xpath("//marc:record/marc:datafield")[i]["tag"].to_i
      expect(this_tag >= last_tag).to eq(true)
      last_tag = this_tag
    end
  end
end

 describe "040 cataloging source field" do
   before(:each) do
     @marc = get_marc(create(:json_resource))      
     @xml = @marc.to_xml
   end

   it "MARC record should only have one 040 element in the document" do
     forty_count = @xml.scan(/(?=#{'tag="040"'})/).count
     expect(forty_count).to eql(1)
   end
  end

  describe "datafield 110 name mapping" do

    before(:each) do
      @name = build(:json_name_corporate_entity)
      agent = create(:json_agent_corporate_entity,
                    :names => [@name])
      @resource = create(:json_resource,
                         :linked_agents => [
                                            {
                                              'role' => 'creator',
                                              'ref' => agent.uri
                                            }
                                           ]
                         )

      @marc = get_marc(@resource)
    end

    it "maps primary_name to subfield 'a'" do
      @marc.should have_tag "datafield[@tag='110']/subfield[@code='a']" => @name.primary_name
    end
  end


  describe "datafield 245 mapping" do
    before(:each) do

      @dates = ['inclusive', 'bulk'].map {|type|
        range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
        build(:json_date,
              :date_type => type,
              :begin => range[0],
              :end => range[1],
              :expression => [true, false].sample ? generate(:string) : nil
              )
      }

      2.times { @dates << build(:json_date) }


      @resource = create(:json_resource,
                         :dates => @dates)

      @marc = get_marc(@resource)
    end

    it "maps the first inclusive date to subfield 'f'" do
      date = @dates.find{|d| d.date_type == 'inclusive'}

      if date.expression
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.expression}"
      else
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.begin} - #{date.end}"
      end
    end

    it "adds a comma after $a if a date is defined" do
      expect(@marc.at("datafield[@tag='245']/subfield[@code='a']/text()").to_s[-1]).to eq(",")
    end


    it "maps the first bulk date to subfield 'g'" do
      date = @dates.find{|d| d.date_type == 'bulk'}

      if date.expression
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{date.expression}"
      else
        @marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{date.begin} - #{date.end}"
      end
    end


    it "doesn't create more than two dates" do
      %w(f g).each do |code|
        @marc.should_not have_tag "datafield[@tag='245']/subfield[@code='#{code}'][2]"
      end
    end

    it "sets first indicator to 0 if the resource has no creator" do
      @marc.should have_tag "datafield[@tag='245' and @ind1='0']"
    end
  end

  describe "datafield 245 mapping dates" do
    before(:each) do

      @range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort

      @inclusive_single = build(:json_date,
                                :date_type => 'inclusive',
                                :begin => @range[0],
                                :end => nil,
                                :expression => nil)

      @bulk_single = build(:json_date,
                           :date_type => 'bulk',
                           :begin => @range[0],
                           :end => nil,
                           :expression => nil)

      @inclusive_range = build(:json_date,
                               :date_type => 'inclusive',
                               :begin => @range[0],
                               :end => @range[1],
                               :expression => nil)


      @bulk_range = build(:json_date,
                          :date_type => 'bulk',
                          :begin => @range[0],
                          :end => @range[1],
                          :expression => nil)

      @inclusive_expression = build(:json_date,
                                    :date_type => 'inclusive',
                                    :begin => @range[0],
                                    :end => @range[1],
                                    :expression => "1981ish")

      @bulk_expression = build(:json_date,
                               :date_type => 'bulk',
                               :begin => @range[0],
                               :end => @range[1],
                               :expression => "1991ish")

    end

    it "should use expression in bulk and inclusive dates if provided" do
      dates = [@inclusive_expression, @bulk_expression]

      resource = create(:json_resource, :dates => dates)
      marc = get_marc(resource) 

      marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "1981ish"
      marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "1991ish"
    end

    it "should follow the format for single dates" do
      dates = [@inclusive_single, @bulk_single]

      resource = create(:json_resource, :dates => dates)
      marc = get_marc(resource) 

      marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{@range[0]}"
      marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{@range[0]}"
    end

    it "should follow the format for ranged dates" do
      dates = [@inclusive_range, @bulk_range]

      resource = create(:json_resource, :dates => dates)
      marc = get_marc(resource) 

      marc.should have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{@range[0]} - #{@range[1]}"
      marc.should have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{@range[0]} - #{@range[1]}"
    end
  end


  describe "datafield 3xx mapping" do
    before(:each) do

      @notes = %w(arrangement fileplan).map { |type|
        build(:json_note_multipart,
              :type => type,
              :publish => true)
      }

      @extents = (0..5).to_a.map{ build(:json_extent) }
      @resource = create(:json_resource,
                         :extents => @extents,
                         :notes => @notes)

      @marc = get_marc(@resource)
    end

    it "creates a 300 field for each extent" do
      @marc.should have_tag "datafield[@tag='300'][#{@extents.count}]"
      @marc.should_not have_tag "datafield[@tag='300'][#{@extents.count + 1}]"
    end


    it "maps extent number to subfield a, and type to subfield f" do
      type = I18n.t("enumerations.extent_extent_type.#{@extents[0].extent_type}")
      extent = "#{@extents[0].number} #{type}"
      @marc.should have_tag "datafield[@tag='300'][1]/subfield[@code='a']" => @extents[0].number
      @marc.should have_tag "datafield[@tag='300'][1]/subfield[@code='f']" => type
    end


    it "maps container summary to subfield f" do
      @extents.each do |e|
        next unless e.container_summary
        @marc.should have_tag "datafield[@tag='300']/subfield[@code='f']" => e.container_summary
      end
    end


    it "maps arrangment and fileplan notes to datafield 351" do
      @notes.each do |note|
        @marc.should have_tag "datafield[@tag='351']/subfield[@code='a'][1]" => note_content(note)
      end
    end
  end

  describe "datafield 65x mapping" do
    before(:all) do

      @subjects = []
      30.times {
        subject = create(:json_subject)
        # only count subjects that map to 65x fields
        @subjects << subject unless ['uniform_title', 'temporal'].include?(subject.terms[0]['term_type'])
      }
     linked_subjects = @subjects.map {|s| {:ref => s.uri} }




      @extents = [ build(:json_extent)]
      @resource = create(:json_resource,
                         :extents => @extents,
                         :subjects => linked_subjects)

      @marc = get_marc(@resource)

    end

    after(:all) do
      @subjects.each {|s| s.delete }
      @resource.delete
    end

    it "creates a 65x field for each subject" do
      xmlnotes = []
      (0..9).each do |i|
        tag = "65#{i.to_s}"
        @marc.xpath("//xmlns:datafield[@tag = '#{tag}']").each { |x| xmlnotes << x  }
      end
      #puts xmlnotes.map{|n| n.inner_text }.inspect
      #puts @subjects.map{|s| s.to_hash }.inspect

      xmlnotes.length.should eq(@subjects.length)
    end
  end

  describe "strips mixed content" do
    before(:each) do

      @dates = ['inclusive', 'bulk'].map {|type|
        range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
        build(:json_date,
              :date_type => type,
              :begin => range[0],
              :end => range[1],
              :expression => [true, false].sample ? generate(:string) : nil
              )
      }

      2.times { @dates << build(:json_date) }


      @resource = create(:json_resource,
                         :dates => @dates,
                         :id_0 => "999",
                         :title => "Foo <emph render='bold'>BAR</emph> Jones")

      @marc = get_marc(@resource)
    end

    it "should strip out the mixed content in title" do
      @marc.should have_tag "datafield[@tag='245']/subfield[@code='a']"
      expect(@marc.at("datafield[@tag='245']/subfield[@code='a']/text()").to_s).to match(/Foo  BAR  Jones/)
    end
  end


  describe "record leader mappings" do
    before(:all) do
      @resource1 = create(:json_resource,
                          :level => 'collection',
                          :finding_aid_description_rules => 'dacs')
      @resource2 = create(:json_resource,
                          :level => 'item',
                          :dates => [
                                     build(:json_date,
                                           :date_type => 'single',
                                           :begin => '1900')
                                    ]
                          )
      @resource3 = create(:json_resource,
                          :level => 'item',
                          :dates => [
                                     build(:json_date,
                                           :date_type => 'bulk',
                                           :begin => '1800',
                                           :end => '1850')
                                    ]
                          )

      @marc1 = get_marc(@resource1)
      @marc2 = get_marc(@resource2)
      @marc3 = get_marc(@resource3)

    end


    after(:all) do
      @resource1.delete
      @resource2.delete
      @resource3.delete
    end

    it "provides default values for record/leader: 00000np$ a2200000 u 4500" do
      @marc1.at("record/leader").should have_inner_text(/00000np.aa2200000\su\s4500/)
    end


    it "assigns 'm' to the 7th leader character for resources with level 'item'" do
      @marc1.at("record/leader").should have_inner_text(/^.{7}c.*/)
      @marc2.at("record/leader").should have_inner_text(/^.{7}m.*/)

    end

    it "maps resource record mtime to record/controlfield[@tag='008']/text()[0..5]" do
      @marc1.at("record/controlfield[@tag='008']").should have_inner_text(/^\d{6}/)
    end

    it "sets record/controlfield[@tag='008']/text()[6] according to resource.level" do
      @marc1.at("record/controlfield[@tag='008']").should have_inner_text(/^.{6}i/)
      @marc2.at("record/controlfield[@tag='008']").should have_inner_text(/^.{6}s/)
      @marc3.at("record/controlfield[@tag='008']").should have_inner_text(/^.{6}i/)
    end

    it "sets record/controlfield[@tag='008']/text()[7..10] with resource.dates[0]['begin']" do
      @marc2.at("record/controlfield").should have_inner_text(/^.{7}1900/)
    end

    it "sets record/controlfield[@tag='008']/text()[11..14] with resource.dates[0]['end']" do
      @marc3.at("record/controlfield").should have_inner_text(/^.{11}1850/)
    end

    it "sets record/controlfield[@tag='008']/text()[15..16] with 'xx'" do
      @marc1.at("record/controlfield").should have_inner_text(/^.{15}xx/)
    end

    it "sets record/controlfield[@tag='008']/text()[35..37] with resource.language" do
      @marc1.at("record/controlfield").should have_inner_text(Regexp.new("^.{35}#{@resource1.language}"))
    end

    it "sets record/controlfield[@tag='008']/text()[38..39] with ' d'" do
      @marc1.at("record/controlfield").should have_inner_text(/.{38}\sd/)
    end

    it "maps repository.org_code to datafield[@tag='040' and @ind1=' ' and @ind2=' '] subfields a and c" do
      org_code = JSONModel(:repository).find($repo_id).org_code
      @marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='a']").should have_inner_text(org_code)
      @marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='c']").should have_inner_text(org_code)
    end

    it "maps language code to datafield[@tag='040' and @ind1=' ' and @ind2=' '] subfield b" do
      org_code = JSONModel(:repository).find($repo_id).org_code
      @marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='b']").should have_inner_text(@resource1.language)
    end

    it "maps resource.finding_aid_description_rules to df[@tag='040' and @ind1=' ' and @ind2=' ']/sf[@code='e']" do
      @marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='e']").should have_inner_text(@resource1.finding_aid_description_rules)
    end


    it "maps resource.language to df[@tag='041' and @ind1='0' and @ind2=' ']/sf[@code='a']" do
      @marc1.at("datafield[@tag='041'][@ind1='0'][@ind2=' ']/subfield[@code='a']").should have_inner_text(@resource1.language)
    end


    it "maps resource.id_\\d to df[@tag='099' and @ind1=' ' and @ind2=' ']/sf[@code='a']" do
      ids = (0..3).map {|i|@resource1.send("id_#{i}") }.compact.join('.')
      @marc1.at("datafield[@tag='099'][@ind1=' '][@ind2=' ']/subfield[@code='a']").should have_inner_text(ids)
    end

    it "maps repository identifier data to df 852" do
      repo = JSONModel(:repository).find($repo_id)

      df = @marc1.df('852', ' ', ' ')
      df.sf_t('a').should include(repo.org_code)
      df.sf_t('b').should eq(repo.name)
      df.sf_t('c').should eq((0..3).map{|i| @resource1.send("id_#{i}")}.compact.join('.'))
    end
  end

  describe "agents: include unpublished flag" do
    before(:all) do
      @agents = []
      [
        [:json_agent_person,
          :names => [build(:json_name_person,
                           :prefix => "MR"),
          :publish => false]
        ],
        [:json_agent_corporate_entity,  {:publish => false} ],
        [:json_agent_family, {:publish => false} ],
      ].each do |type_and_opts|
        @agents << create(type_and_opts[0], type_and_opts[1])
      end

      @resource = create(:json_resource,
                             :linked_agents => @agents.map.each_with_index {|a, j|
                              {
                                :ref => a.uri,
                                :role => (j == 0) ? 'creator' : 'subject',
                                :terms => [build(:json_term), build(:json_term)],
                                :relator => generate(:relator)
                              }}
        )

      @marc_unpub_incl   = get_marc(@resource, true)
      @marc_unpub_unincl = get_marc(@resource, false)
    end


    after(:all) do
      @resource.delete
      @agents.each {|a| a.delete}
    end

    it "should not create elements for unpublished agents if include_unpublished is false" do
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{100}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{610}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{600}']").length).to eq(0)
    end

    it "should create elements for unpublished agents if include_unpublished is true" do
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{100}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{610}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{600}']").length > 0).to eq(true)
    end
  end


  describe 'linked agent mappings' do
    before(:all) do
      @agents = []
      [
        [:json_agent_person,
          :names => [build(:json_name_person,
                           :prefix => "MR")]
        ],
        [:json_agent_corporate_entity,  {}],
        [:json_agent_family, {}],
        [:json_agent_person,
          :names => [build(:json_name_person,
                           :prefix => "MS")]
        ],
        [:json_agent_person,
          :names => [build(:json_name_person,
                           :prefix => "QR")]
        ],
        [:json_agent_person,
          :names => [build(:json_name_person,
                           :prefix => "FZ")]
        ],
        [:json_agent_family, {}]
      ].each do |type_and_opts|
        @agents << create(type_and_opts[0], type_and_opts[1])
      end

      # r0 created by a person and a person
      # r1 created by a corp and a person
      # r2 created by a family and a person
      @resources = [0,1,2].map {|i|
        create(:json_resource,
               :linked_agents => @agents.map.each_with_index {|a, j|
                 {
                   :ref => a.uri,
                   :role => (j == i || j > 2) ? 'creator' : 'subject',
                   :terms => [build(:json_term), build(:json_term)],
                   :relator => generate(:relator)
                 }
               })
        }


      @marcs = @resources.map {|r| get_marc(r)}

    end


    after(:all) do
      @resources.each {|r| r.delete}
      @agents.each {|a| a.delete}
    end


    it "maps the first creator to df[@tag='100'] when it's a person" do
      name = @agents[0]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[0].at("datafield[@tag='100'][@ind1='#{inverted}'][@ind2=' ']")
      df.at("subfield[@code='a']").should have_inner_text name_string
      df.at("subfield[@code='b']").should have_inner_text name['number']
      df.at("subfield[@code='c']").should have_inner_text %w(prefix title suffix).map{|p| name[p]}.compact.join(', ')
      df.at("subfield[@code='d']").should have_inner_text name['dates']
      df.at("subfield[@code='q']").should have_inner_text name['fuller_form']
    end


    it "maps the first creator to df[@tag='110'] when it's a corp" do
      name = @agents[1]['names'][0]

      df = @marcs[1].at("datafield[@tag='110'][@ind1='2'][@ind2=' ']")

      df.at("subfield[@code='a']").should have_inner_text name['primary_name']
      df.at("subfield[@code='b']").should have_inner_text name['subordinate_name_1']
     df.at("subfield[@code='n']").should have_inner_text name['number']
    end


    it "maps the first creator to df[@tag='100'] when it's a family" do
      name = @agents[2]['names'][0]

      df = @marcs[2].at("datafield[@tag='100'][@ind1='3'][@ind2=' ']")

      df.at("subfield[@code='a']").should have_inner_text name['family_name']
      df.at("subfield[@code='c']").should have_inner_text name['qualifier']
      df.at("subfield[@code='d']").should have_inner_text name['dates']
    end


    it "maps subject to 600 when it's a person" do
      name = @agents[0]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      ind2 =  source_to_code(name['source'])

      name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[1].at("datafield[@tag='600'][@ind1='#{inverted}'][@ind2='#{ind2}']")

      df.at("subfield[@code='a']").should have_inner_text name_string
      df.at("subfield[@code='b']").should have_inner_text name['number']
      df.at("subfield[@code='c']").should have_inner_text %w(prefix title suffix).map{|p| name[p]}.compact.join(', ')
      df.at("subfield[@code='d']").should have_inner_text name['dates']
    end


   it "maps subject agent to df[@tag='610'] when it's a corp" do
      name = @agents[1]['names'][0]
      ind2 =  source_to_code(name['source'])

      df = @marcs[0].at("datafield[@tag='610'][@ind1='2'][@ind2='#{ind2}']")

      df.at("subfield[@code='a']").should have_inner_text name['primary_name']
      df.at("subfield[@code='b']").should have_inner_text name['subordinate_name_1']
     df.at("subfield[@code='n']").should have_inner_text name['number']
    end


    it "maps subject agent to df[@tag='600'] when it's a family" do
      name = @agents[2]['names'][0]
      ind2 =  source_to_code(name['source'])

      df = @marcs[0].at("datafield[@tag='600'][@ind1='3'][@ind2='#{ind2}']")

      df.at("subfield[@code='a']").should have_inner_text name['family_name']
      df.at("subfield[@code='c']").should have_inner_text name['qualifier']
      df.at("subfield[@code='d']").should have_inner_text name['dates']
    end


    it "maps the second creator to df[@tag='700'] when it's a person" do
      name = @agents[3]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[1].at("datafield[@tag='700'][@ind1='#{inverted}'][@ind2=' ']")

      df.at("subfield[@code='a']").should have_inner_text name_string
      df.at("subfield[@code='b']").should have_inner_text name['number']
      df.at("subfield[@code='c']").should have_inner_text %w(prefix title suffix).map{|p| name[p]}.compact.join(', ')
      df.at("subfield[@code='d']").should have_inner_text name['dates']
    end

    # opposite case of spec found on line 143
    it "245 tag: sets first indicator to 1 if the resource has an creator" do
      @marcs[0].should have_tag "marc:datafield[@tag='245' and @ind1='1']"
    end

    it "stores qualifier in $c for secondary family creators " do
      name = @agents[6]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'

      expect(@marcs[0].xpath("//marc:datafield[@tag='700']/marc:subfield[@code='c'][contains(text(), '#{name['qualifier']}')]").length).to eq(1)
    end

    it "creates multiple 700 tags for multiple owner agents" do
      # 4 owner agents are linked above in before block in line 373, @agents

      expect(@marcs[0].xpath("//marc:datafield[@tag='700']").length).to eq(4)
    end
  end

  describe "note mappings" do

    let(:note_types) {
      %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial arrangement fileplan accessrestrict abstract scopecontent prefercite acqinfo bibliography index altformavail originalsloc userestrict legalstatus relatedmaterial custodhist appraisal accruals bioghist)
    }

    before(:all) do

      @resource = create(:json_resource,
                         :notes => full_note_set(true),
                         :publish => true)

      @marc = get_marc(@resource)
    end

    after(:all) do
      @resource.delete
    end


    it "maps notes of type (odd|dimensions|physdesc|materialspec|physloc|phystech|physfacet|processinfo|separatedmaterial) to df 500, sf a" do
      xml_content = @marc.df('500', ' ', ' ').sf_t('a')
      types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial)
      notes = @resource.notes.select{|n| types.include?(n['type'])}
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
      note_test(@resource, @marc, %w(accessrestrict), ['506', ' ', ' '], 'a')
    end


    it "maps notes of type 'abstract' to df 520 ('3', ' '), sf a" do
      note_test(@resource, @marc, %w(abstract), ['520', '3', ' '], 'a')
    end


    it "maps notes of type 'scopecontent' to df 520 ('2', ' '), sf a" do
      note_test(@resource, @marc, %w(scopecontent), ['520', '2', ' '], 'a')
    end


    it "maps notes of type 'prefercite' to df 524 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(prefercite), ['524', ' ', ' '], 'a')
    end


    it "maps notes of type 'altformavail' to df 535 ('2', ' '), sf a" do
      note_test(@resource, @marc, %w(altformavail), ['535', '2', ' '], 'a')
    end


    it "maps notes of type 'originalsloc' to df 535 ('1', ' '), sf a" do
      note_test(@resource, @marc, %w(originalsloc), ['535', '1', ' '], 'a')
    end


    it "maps notes of type 'userestrict' | 'legalstatus' to df 540 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(userestrict legalstatus), ['540', ' ', ' '], 'a')
    end


    it "maps public notes of type 'acqinfo' to df 541 ('1', ' '), sf a" do
      note_test(@resource, @marc, %w(acqinfo), ['541', '1', ' '], 'a', {'publish' => true})
    end


    it "maps private notes of type 'acqinfo' to df 541 ('0', ' '), sf a" do
      note_test(@resource, @marc, %w(acqinfo), ['541', '0', ' '], 'a', {'publish' => false})
    end


    it "maps notes of type 'relatedmaterial' to df 544 (' ', ' '), sf d" do
      note_test(@resource, @marc, %w(relatedmaterial), ['544', ' ', ' '], 'd')
    end


    it "maps notes of type 'bioghist' to df 545 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(bioghist), ['545', ' ', ' '], 'a')
    end


    it "maps notes of type 'langmaterial' to df 546 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(langmaterial), ['546', ' ', ' '], 'a')
    end


    it "maps resource.ead_location to df 856 ('4', '2'), sf u" do
      df = @marc.df('856', '4', '2')
      df.sf_t('u').should eq(@resource.ead_location)
      df.sf_t('z').should eq("Finding aid online:")
    end

    it "maps resource.finding_aid_note to df 555 ('0', ' '), sf u" do
      df = @marc.df('555', '0', ' ')
      df.sf_t('u').should eq(@resource.finding_aid_note)
      df.sf_t('3').should eq("Finding aids:")
    end

    it "maps public notes of type 'custodhist' to df 561 ('1', ' '), sf a" do
      note_test(@resource, @marc, %w(custodhist), ['561', '1', ' '], 'a', {'publish' => true})
    end


    it "maps private notes of type 'custodhist' to df 561 ('0', ' '), sf a" do
      note_test(@resource, @marc, %w(custodhist), ['561', '0', ' '], 'a', {'publish' => false})
    end


    it "maps public notes of type 'appraisal' to df 583 ('1', ' '), sf a" do
      note_test(@resource, @marc, %w(appraisal), ['583', '1', ' '], 'a', {'publish' => true})
    end


    it "maps private notes of type 'appraisal' to df 583 ('0', ' '), sf a" do
      note_test(@resource, @marc, %w(appraisal), ['583', '0', ' '], 'a', {'publish' => false})
    end


    it "maps notes of type 'accruals' to df 584 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(accruals), ['584', ' ', ' '], 'a')
    end

  end

  describe "notes: include unpublished flag" do
    before(:all) do
      @resource = create(:json_resource,
                         :notes => full_note_set(false))

      @marc_unpub_incl   = get_marc(@resource, true)
      @marc_unpub_unincl = get_marc(@resource, false)
    end

    after(:all) do
      @resource.delete
    end

    it "should not create elements for unpublished notes if include_unpublished is false" do
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{506}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{524}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{535}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{540}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{541}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{544}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{545}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{561}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{583}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{584}']").length).to eq(0)
    end

    it "should create elements for unpublished notes if include_unpublished is true" do
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{506}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{524}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{535}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{540}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{541}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{544}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{545}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{561}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{583}']").length > 0).to eq(true)
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{584}']").length > 0).to eq(true)
    end

  end

  describe "notes: inherit publish from parent" do
    before(:all) do
      @resource = create(:json_resource,
                         :notes => full_note_set(true),
                         :publish => false)

      @marc_unpub_unincl = get_marc(@resource, false)
    end

    after(:all) do
      @resource.delete
    end

    it "should not create elements for published notes if they have a parent with publish == false" do
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{506}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{524}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{535}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{540}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{541}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{544}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{545}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{561}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{583}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{584}']").length).to eq(0)
    end
  end

  describe "049 OCLC tag" do
    before(:all) do
      @resource = create(:json_resource)
      @org_code = JSONModel(:repository).find($repo_id).org_code

      @marc = get_marc(@resource)
    end

    after(:all) do
      @resource.delete
    end


    it "maps org_code to 049 tag" do
      @marc.at("datafield[@tag='049'][@ind1=' '][@ind2=' ']/subfield[@code='a']").should have_inner_text(@org_code)
    end
  end


end
