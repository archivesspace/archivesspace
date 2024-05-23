require_relative 'export_spec_helper'

# TODO: Fix tests to assume that not all subfields will exist in all scenarios.

describe 'MARC Export' do

  before(:all) do
    as_test_user('admin') do
      $old_repo_id = $repo_id
      @repo = create(:json_repository)
      $repo_id = @repo.id

      JSONModel.set_repository($repo_id)
    end
  end

  after(:all) do
    as_test_user('admin') do
      $repo_id = $old_repo_id
      JSONModel.set_repository($repo_id)
    end
  end


  def note_test(resource, marc, note_types, dfcodes, sfcode, filters = {})
    notes = resource.notes.select {|n| note_types.include?(n['type'])}
    filters.each do |k, v|
      notes.reject! {|n| n[k] != v }
    end

    return unless notes.count > 0
    xml_content = marc.df(*dfcodes).sf_t(sfcode)
    expect(xml_content).not_to be_empty
    note_string = notes.map {|n| note_content(n)}.join('')
    xml_content.gsub!(".", "") # code to append punctuation can interfere with this test.
    expect(xml_content).to match(/#{note_string}/)
  end

  def lang_note_test(notes, marc, dfcodes, sfcode)
    return unless notes.count > 0
    xml_content = marc.df(*dfcodes).sf_t(sfcode)
    expect(xml_content).not_to be_empty
    note_string = notes.map {|n| note_content(n)}.join('')
    xml_content.gsub!(".", "") # code to append punctuation can interfere with this test.
    expect(xml_content).to match(/#{note_string}/)
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
       as_test_user('admin') do
         @marc = get_marc(create(:json_resource))
         @xml = @marc.to_xml
       end
     end

     after(:all) do
       as_test_user('admin') do
         $repo_id = $old_repo_id
         JSONModel.set_repository($repo_id)
       end
     end

     it "root node should have xmlns:xsi defined" do
       expect(@xml).to match(/<collection.*xmlns:xsi="http:\/\/www.w3.org\/2001\/XMLSchema-instance"/)
     end

     it "root node should have xsi:schemaLocation defined" do
       expect(@xml).to match(/<collection.*xsi:schemaLocation="http:\/\/www.loc.gov\/MARC21\/slim https:\/\/www.loc.gov\/standards\/marcxml\/schema\/MARC21slim.xsd"/)
     end
   end

  describe "datafield element order" do
    before(:each) do
      as_test_user('admin') do
        @marc = get_marc(create(:json_resource))
        @xml = @marc.to_xml
      end
    end

    after(:all) do
      as_test_user('admin') do
        $repo_id = $old_repo_id
        JSONModel.set_repository($repo_id)
      end
    end

    it "should generate XML with the datafield tags in numerical order" do
      datafield_element_count = @marc.xpath("//marc:record/marc:datafield").length
      last_tag = 0

      # loop through all tags. make sure that datafield[@tag] is a smaller number than the preceeding one.
      0.upto(datafield_element_count - 1) do |i|
        this_tag = @marc.xpath("//marc:record/marc:datafield")[i]["tag"].to_i
        expect(this_tag >= last_tag).to be_truthy
        last_tag = this_tag
      end
    end
  end

  describe "040 cataloging source field" do
     before(:each) do
       as_test_user('admin') do
         @marc = get_marc(create(:json_resource))
         @xml = @marc.to_xml
       end
     end

     after(:all) do
       as_test_user('admin') do
         $repo_id = $old_repo_id
         JSONModel.set_repository($repo_id)
       end
     end

     it "MARC record should only have one 040 element in the document" do
       forty_count = @xml.scan(/(?=#{'tag="040"'})/).count
       expect(forty_count).to eql(1)
     end
   end

  describe "datafield 110 name mapping" do

    before(:each) do
      as_test_user('admin') do
        @name = build(:json_name_corporate_entity)
        @agent = create(:json_agent_corporate_entity_full_subrec,
                      :names => [@name])
        @resource = create(:json_resource,
                           :linked_agents => [
                                              {
                                                'role' => 'creator',
                                                'ref' => @agent.uri
                                              }
                                             ]
                           )

        @marc = get_marc(@resource)
      end
    end

    after(:all) do
      as_test_user('admin') do
        $repo_id = $old_repo_id
        JSONModel.set_repository($repo_id)
      end
    end

    it "maps primary_name to subfield 'a'" do
      expect(@marc).to have_tag "datafield[@tag='110']/subfield[@code='a']" => @name.primary_name + "." || @name.primary_name + ","
    end

    it "maps primary agent_record_identifier to subfield '0'" do
      primary_agent_record_identifier = @agent['agent_record_identifiers'].first['record_identifier']
      expect(@marc).to have_tag "datafield[@tag='110']/subfield[@code='0']" => primary_agent_record_identifier
    end
  end


  describe "datafield 245 mapping" do
    before(:each) do
      as_test_user('admin') do

        @dates = ['inclusive', 'bulk'].map {|type|
          range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
          build(:json_date,
                :date_type => type,
                :begin => range[0],
                :end => range[1],
                :expression => [true, false].sample ? generate(:alphanumstr) : nil
                )
        }

        2.times { @dates << build(:json_date) }


        @resource = create(:json_resource,
                           :dates => @dates)

        @marc = get_marc(@resource)

      end
    end

    after(:all) do
      as_test_user('admin') do
        $repo_id = $old_repo_id
        JSONModel.set_repository($repo_id)
      end
    end

    it "maps the first inclusive date to subfield 'f'" do
      date = @dates.find {|d| d.date_type == 'inclusive'}

      if date.expression
        expect(@marc).to have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.expression}"
      else
        expect(@marc).to have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{date.begin} - #{date.end}"
      end
    end

    it "adds a comma after $a if a date is defined" do
      expect(@marc.at("datafield[@tag='245']/subfield[@code='a']/text()").to_s[-1]).to eq(",")
    end


    it "maps the first bulk date to subfield 'g'" do
      date = @dates.find {|d| d.date_type == 'bulk'}

      if date.expression
        expect(@marc).to have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{date.expression}"
      else
        expect(@marc).to have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{date.begin} - #{date.end}"
      end
    end


    it "doesn't create more than two dates" do
      %w(f g).each do |code|
        expect(@marc).not_to have_tag "datafield[@tag='245']/subfield[@code='#{code}'][2]"
      end
    end

    it "sets first indicator to 0 if the resource has no creator" do
      expect(@marc).to have_tag "datafield[@tag='245' and @ind1='0']"
    end
  end

  describe "datafield 245 mapping dates" do
    before(:each) do
      as_test_user('admin') do

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
    end

    after(:all) do
      as_test_user('admin') do
        $repo_id = $old_repo_id
        JSONModel.set_repository($repo_id)
      end
    end

    it "should use expression in bulk and inclusive dates if provided" do
      dates = [@inclusive_expression, @bulk_expression]

      resource = create(:json_resource, :dates => dates)
      marc = get_marc(resource)

      expect(marc).to have_tag "datafield[@tag='245']/subfield[@code='f']" => "1981ish"
      expect(marc).to have_tag "datafield[@tag='245']/subfield[@code='g']" => "1991ish"
    end

    it "should follow the format for single dates" do
      dates = [@inclusive_single, @bulk_single]

      resource = create(:json_resource, :dates => dates)
      marc = get_marc(resource)

      expect(marc).to have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{@range[0]}"
      expect(marc).to have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{@range[0]}"
    end

    it "should follow the format for ranged dates" do
      dates = [@inclusive_range, @bulk_range]

      resource = create(:json_resource, :dates => dates)
      marc = get_marc(resource)

      expect(marc).to have_tag "datafield[@tag='245']/subfield[@code='f']" => "#{@range[0]} - #{@range[1]}"
      expect(marc).to have_tag "datafield[@tag='245']/subfield[@code='g']" => "#{@range[0]} - #{@range[1]}"
    end
  end


  describe "datafield 3xx mapping" do
    before(:each) do
      as_test_user('admin') do

        @notes = %w(arrangement fileplan).map { |type|
          build(:json_note_multipart,
                :type => type,
                :publish => true)
        }

        @extents = (0..5).to_a.map { build(:json_extent) }
        @resource = create(:json_resource,
                           :extents => @extents,
                           :notes => @notes)

        @marc = get_marc(@resource)

      end
    end

    after(:all) do
      as_test_user('admin') do
        $repo_id = $old_repo_id
        JSONModel.set_repository($repo_id)
      end
    end

    it "creates a 300 field for each extent" do
      expect(@marc).to have_tag "datafield[@tag='300'][#{@extents.count}]"
      expect(@marc).not_to have_tag "datafield[@tag='300'][#{@extents.count + 1}]"
    end


    it "maps extent number to subfield a, and type to subfield f" do
      type = I18n.t("enumerations.extent_extent_type.#{@extents[0].extent_type}")
      extent = "#{@extents[0].number} #{type}"
      expect(@marc).to have_tag "datafield[@tag='300'][1]/subfield[@code='a']" => @extents[0].number
      expect(@marc).to have_tag "datafield[@tag='300'][1]/subfield[@code='f']" => type
    end


    it "maps container summary to subfield f" do
      @extents.each do |e|
        next unless e.container_summary
        expect(@marc).to have_tag "datafield[@tag='300']/subfield[@code='f']" => e.container_summary
      end
    end


    it "maps arrangement and fileplan notes to datafield 351, and appends trailing punctuation" do
      @notes.each do |note|
        expect(@marc).to have_tag "datafield[@tag='351']/subfield[@code='a'][1]" => note_content(note) + "."
      end
    end
  end

  describe "datafield 65x mapping" do
    before(:all) do
      as_test_user('admin', true) do

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

        raise Sequel::Rollback
      end
    end

    it "creates a 65x field for each subject" do
      xmlnotes = []
      (0..9).each do |i|
        tag = "65#{i.to_s}"
        @marc.xpath("//xmlns:datafield[@tag = '#{tag}']").each { |x| xmlnotes << x }
      end
      #puts xmlnotes.map{|n| n.inner_text }.inspect
      #puts @subjects.map{|s| s.to_hash }.inspect

      expect(xmlnotes.length).to eq(@subjects.length)
    end

    it "maps authority_id to $0" do
      @subjects.each do |s|
        expect(@marc).to have_tag "subfield[@code='0']" => "#{s['authority_id']}"
      end
    end
  end

  describe "strips mixed content" do
    before(:each) do
      as_test_user('admin') do

        @dates = ['inclusive', 'bulk'].map {|type|
          range = [nil, nil].map { generate(:yyyy_mm_dd) }.sort
          build(:json_date,
                :date_type => type,
                :begin => range[0],
                :end => range[1],
                :expression => [true, false].sample ? generate(:alphanumstr) : nil
                )
        }

        2.times { @dates << build(:json_date) }


        @resource = create(:json_resource,
                           :dates => @dates,
                           :id_0 => "999",
                           :title => "Foo <emph render='bold'>BAR</emph> Jones")

        @marc = get_marc(@resource)

      end
    end

    after(:all) do
      as_test_user('admin') do
        $repo_id = $old_repo_id
        JSONModel.set_repository($repo_id)
      end
    end

    it "should strip out the mixed content in title" do
      expect(@marc).to have_tag "datafield[@tag='245']/subfield[@code='a']"
      expect(@marc.at("datafield[@tag='245']/subfield[@code='a']/text()").to_s).to match(/Foo  BAR  Jones/)
    end
  end

  describe "record leader mappings - country not defined in repo" do
    before(:all) do
      as_test_user('admin') do
        @repo_nc = create(:json_repository,
                          :country => nil)

        $another_repo_id = $repo_id
        $repo_id = @repo_nc.id

        JSONModel.set_repository($repo_id)

        @resource1 = create(:json_resource,
                            :level => 'collection',
                            :finding_aid_description_rules => 'dacs')

        @marc1 = get_marc(@resource1)
      end
    end

    after(:all) do
      as_test_user('admin') do
        @resource1.delete
        $repo_id = $another_repo_id

        JSONModel.set_repository($repo_id)
      end
    end

    it "sets record/controlfield[@tag='008']/text()[15..16] (country code) with xx" do
      expect(@marc1.at("record/controlfield")).to have_inner_text(/^.{15}xx/)
    end
  end

  describe "record leader mappings - US is country defined" do
    before(:all) do
      as_test_user('admin', true) do
        @repo_us = create(:json_repository,
                          :country => 'US')

        $another_repo_id = $repo_id
        $repo_id = @repo_us.id

        JSONModel.set_repository($repo_id)

        @resource1 = create(:json_resource,
                            :level => 'collection',
                            :finding_aid_description_rules => 'dacs')

        @marc1 = get_marc(@resource1)

        raise Sequel::Rollback
      end
    end


    it "sets record/controlfield[@tag='008']/text()[15..16] (country code) with xxu for US special case" do
      expect(@marc1.at("record/controlfield")).to have_inner_text(/^.{15}xxu/)
    end
  end

  describe "record leader mappings - country defined - NOT US" do
    before(:all) do
      as_test_user('admin', true) do
        @repo_not_us = create(:json_repository,
                              :country => 'TH')

        $another_repo_id = $repo_id
        $repo_id = @repo_not_us.id

        JSONModel.set_repository($repo_id)

        @resource1 = create(:json_resource,
                            :level => 'collection',
                            :finding_aid_description_rules => 'dacs')

        @marc1 = get_marc(@resource1)

        raise Sequel::Rollback
      end
    end

    it "sets record/controlfield[@tag='008']/text()[15..16] (country code) with xxu for US special case" do
      expect(@marc1.at("record/controlfield")).to have_inner_text(/^.{15}th/)
    end
  end

  describe "record leader mappings - parent_org_defined" do
    before(:all) do
      as_test_user('admin', true) do
        @repo_parent = create(:json_repository,
                              :parent_institution_name => generate(:alphanumstr))

        @parent_institution_name = @repo_parent.parent_institution_name
        @name = @repo_parent.name

        $another_repo_id = $repo_id
        $repo_id = @repo_parent.id

        JSONModel.set_repository($repo_id)

        @resource1 = create(:json_resource,
                            :level => 'collection',
                            :finding_aid_description_rules => 'dacs')

        @marc1 = get_marc(@resource1)

        raise Sequel::Rollback
      end
    end

    it "df 852: if parent name defined, $a gets parent org, $b gets repo name" do
      df = @marc1.df('852', ' ', ' ')
      expect(df.sf_t('a')).to include(@parent_institution_name)
      expect(df.sf_t('b')).to eq(@name)
    end
  end

  describe "record leader mappings - NO org_code defined" do
    before(:all) do
      as_test_user('admin', true) do
        @repo_no_org_code = create(:json_repository,
                                   :org_code => nil)

        @name = @repo_no_org_code.name

        $another_repo_id = $repo_id
        $repo_id = @repo_no_org_code.id

        JSONModel.set_repository($repo_id)

        @resource1 = create(:json_resource,
                            :level => 'collection',
                            :finding_aid_description_rules => 'dacs')

        @marc1 = get_marc(@resource1)

        raise Sequel::Rollback
      end
    end

    it "df 852: if parent org and repo_code UNdefined, $a repo name" do
      df = @marc1.df('852', ' ', ' ')
      expect(df.sf_t('a')).to eq(@name)
    end
  end

  describe "record leader mappings" do
    before(:all) do
      as_test_user('admin', true) do
        @resource1 = create(:json_resource,
                            :level => 'collection',
                            :finding_aid_description_rules => 'dacs',
                            :dates => [
                                       build(:json_date,
                                             :date_type => 'inclusive',
                                             :begin => '1900',
                                             :end => '2000')
                                      ]
                            )
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
        @resource4 = create(:json_resource,
                            :level => 'item',
                            :dates => [
                                       build(:json_date,
                                             :date_type => 'bulk',
                                             :begin => '1800',
                                             :end => '1850')
                                      ],
                            :lang_materials => [
                                           build(:json_lang_material),
                                           build(:json_lang_material),
                                           build(:json_lang_material_with_note)
                                          ]
                            )
        @resource5 = create(:json_resource,
                            :level => 'collection',
                            :dates => [
                                       build(:json_date,
                                             :date_type => 'single',
                                             :begin => '1900')
                                      ]
                            )

        @marc1 = get_marc(@resource1)
        @marc2 = get_marc(@resource2)
        @marc3 = get_marc(@resource3)
        @marc4 = get_marc(@resource4)
        @marc5 = get_marc(@resource5)

        raise Sequel::Rollback
      end
    end

    it "provides default values for record/leader: 00000np$ a2200000 u 4500" do
      expect(@marc1.at("record/leader")).to have_inner_text(/00000np.aa2200000\su\s4500/)
    end


    it "assigns 'm' to the 7th leader character for resources with level 'item'" do
      expect(@marc1.at("record/leader")).to have_inner_text(/^.{7}c.*/)
      expect(@marc2.at("record/leader")).to have_inner_text(/^.{7}m.*/)

    end

    it "maps resource record mtime to record/controlfield[@tag='008']/text()[0..5]" do
      expect(@marc1.at("record/controlfield[@tag='008']")).to have_inner_text(/^\d{6}/)
    end

    it "sets record/controlfield[@tag='008']/text()[6] according date type" do
      expect(@marc1.at("record/controlfield[@tag='008']")).to have_inner_text(/^.{6}i/)
      expect(@marc2.at("record/controlfield[@tag='008']")).to have_inner_text(/^.{6}s/)
      expect(@marc3.at("record/controlfield[@tag='008']")).to have_inner_text(/^.{6}i/)
      expect(@marc5.at("record/controlfield[@tag='008']")).to have_inner_text(/^.{6}s/)
    end


    it "sets record/controlfield[@tag='008']/text()[7..10] with resource.dates[0]['begin']" do
      expect(@marc2.at("record/controlfield")).to have_inner_text(/^.{7}1900/)
    end


    it "sets record/controlfield[@tag='008']/text()[11..14] with resource.dates[0]['end']" do
      expect(@marc3.at("record/controlfield")).to have_inner_text(/^.{11}1850/)
    end


    it "sets record/controlfield[@tag='008']/text()[35..37] with resource.lang_materials[0]['language_and_script']['language']" do
      expect(@marc1.at("record/controlfield")).to have_inner_text(Regexp.new("^.{35}#{@resource1.lang_materials[0]['language_and_script']['language']}"))
    end


    it "sets record/controlfield[@tag='008']/text()[35..37] with 'mul' if more than one language" do
      expect(@marc4.at("record/controlfield")).to have_inner_text(Regexp.new("^.{35}#{'mul'}"))
    end

    it "sets record/controlfield[@tag='008']/text()[38..39] with ' d'" do
      expect(@marc1.at("record/controlfield")).to have_inner_text(/.{38}\sd/)
    end

    it "maps repository.org_code to datafield[@tag='040' and @ind1=' ' and @ind2=' '] subfields a and c" do
      org_code = JSONModel(:repository).find($repo_id).org_code
      expect(@marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='a']")).to have_inner_text(org_code)
      expect(@marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='c']")).to have_inner_text(org_code)
    end

    it "maps finding aid language code to datafield[@tag='040' and @ind1=' ' and @ind2=' '] subfield b" do
      expect(@marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='b']")).to have_inner_text(@resource1.finding_aid_language)
    end

    it "maps resource.finding_aid_description_rules to df[@tag='040' and @ind1=' ' and @ind2=' ']/sf[@code='e']" do
      expect(@marc1.at("datafield[@tag='040'][@ind1=' '][@ind2=' ']/subfield[@code='e']")).to have_inner_text(@resource1.finding_aid_description_rules)
    end


    it "maps languages to repeated df[@tag='041' and @ind1=' ' and @ind2=' ']/sf[@code='a']" do
      language1 = @resource4.lang_materials[0]['language_and_script']['language']
      language2 = @resource4.lang_materials[1]['language_and_script']['language']

      expect(@marc4.at("datafield[@tag='041'][@ind1=' '][@ind2=' ']/subfield[@code='a'][1]")).to have_inner_text(language1)
      expect(@marc4.at("datafield[@tag='041'][@ind1=' '][@ind2=' ']/subfield[@code='a'][2]")).to have_inner_text(language2)
    end


    it "maps language notes to df 546 (' ', ' '), sf a" do

      lang_materials = @resource4.lang_materials.select {|n| n.include?('notes')}.reject {|e| e['notes'] == [] }
      notes = lang_materials[0]['notes']

      lang_note_test(notes, @marc4, ['546', ' ', ' '], 'a')

    end


    it "maps resource.id_\\d to df[@tag='099' and @ind1=' ' and @ind2=' ']/sf[@code='a']" do
      ids = (0..3).map {|i| @resource1.send("id_#{i}") }.compact.join('.')
      expect(@marc1.at("datafield[@tag='099'][@ind1=' '][@ind2=' ']/subfield[@code='a']")).to have_inner_text(ids)
    end

    it "df 852: $a should get org_code if org_code defined and parent_institution_name not" do
      repo = JSONModel(:repository).find($repo_id)

      df = @marc1.df('852', ' ', ' ')
      expect(df.sf_t('a')).to include(repo.org_code)
    end
  end

  describe "agents: include unpublished flag" do
    before(:all) do
      as_test_user('admin', true) do
        @agents = []
        [
          [:json_agent_person,
            :names => [build(:json_name_person,
                             :prefix => "MR"),
            :publish => false]
          ],
          [:json_agent_corporate_entity, {:publish => false} ],
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

        raise Sequel::Rollback
      end
    end

    it "should not create elements for unpublished agents if include_unpublished is false" do
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{100}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{610}']").length).to eq(0)
      expect(@marc_unpub_unincl.xpath("//marc:datafield[@tag = '#{600}']").length).to eq(0)
    end

    it "should create elements for unpublished agents if include_unpublished is true" do
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{100}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{610}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{600}']").length > 0).to be_truthy
    end
  end

  describe 'linked agent mappings with primary agents' do
    before(:all) do
      as_test_user('admin', true) do
        @agents = []
        [
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "MR") ]
          ],
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "MR") ]
          ],
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "MR") ]
          ],

        ].each do |type_and_opts|
          @agents << create(type_and_opts[0], type_and_opts[1])
        end

        @resource = create(:json_resource,
                 :linked_agents => [
                   {
                     :ref => @agents[0].uri,
                     :role => 'creator',
                     :relator => generate(:relator),
                     :is_primary => false
                   },
                   {
                     :ref => @agents[1].uri,
                     :role => 'creator',
                     :relator => generate(:relator),
                     :is_primary => false
                   },
                   {
                     :ref => @agents[2].uri,
                     :role => 'creator',
                     :relator => generate(:relator),
                     :is_primary => true
                   },
                 ])

        @marc = get_marc(@resource)
        raise Sequel::Rollback
      end
    end

    it "maps the creator that is primary to 100 tag" do
      name = @agents[2]['names'][0]
      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marc.at("datafield[@tag='100']")
      resource = @resource['linked_agents'].select { |r| r['role'] == 'creator' }.first

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name_string}/)
    end
  end



  describe 'linked agent mappings' do
    before(:all) do
      as_test_user('admin', true) do
        @agents = []
        [
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "MR") ]
          ],
          [:json_agent_corporate_entity, {}],
          [:json_agent_family,
           names: [ build(:json_name_family,
                          source: "local") ]],
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "MS") ]],
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "QR") ]],
          [:json_agent_person,
           names: [ build(:json_name_person,
                          source: "local",
                          prefix: "FZ") ]],
          [:json_agent_family, {}],
          [:json_agent_person,
           names: [ build(:json_name_person,
                         source: "local",
                         prefix: "QM",
                         authority_id: nil) ]],
          [:json_agent_corporate_entity,
           names: [ build(:json_name_corporate_entity,
                          source: "local",
                          subordinate_name_1: nil,
                          subordinate_name_2: nil,
                          qualifier: nil,
                          number: nil) ]]
        ].each do |type_and_opts|
          @agents << create(type_and_opts[0], type_and_opts[1])
        end

        # r0 100 => @agent[0],
        #    600 => @agent[2],
        #    610 => @agent[1], @agent[8]
        #    700 => @agent[3], @agent[4], @agent[5], @agent[6], @agent[7]
        # r1 110 => @agent[1],
        #    600 => @agent[0], @agent[2],
        #    610 => @agent[8]
        #    700 => @agent[3], @agent[4], @agent[5], @agent[6], @agent[7]
        # r2 110 => @agent[2],
        #    600 => @agent[0],
        #    610 => @agent[1], @agent[8]
        #    700 => @agent[3], @agent[4], @agent[5], @agent[6], @agent[7]
        @resources = [0, 1, 2].map {|i|
          create(:json_resource,
                 :linked_agents => @agents.map.each_with_index {|a, j|
                   {
                     :ref => a.uri,
                     :role => (j == i || j.between?(3, 7)) ? 'creator' : 'subject',
                     :terms => [build(:json_term), build(:json_term)],
                     :relator => (j != 8) ? generate(:relator) : nil
                   }
                 })
        }

        @marcs = @resources.map {|r| get_marc(r)}
        raise Sequel::Rollback
      end
    end

    it "maps the first creator to df[@tag='100'] when it's a person" do
      name = @agents[0]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[0].at("datafield[@tag='100'][@ind1='#{inverted}'][@ind2=' ']")
      resource = @resources[0]['linked_agents'].select { |r| r['role'] == 'creator' }.first

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name_string}/)
      expect(df.at("subfield[@code='b']")).to have_inner_text(/#{name['number']}/)
      expect(df.at("subfield[@code='c']")).to have_inner_text(/#{%w(prefix title suffix).map {|p| name[p]}.compact.join(', ')}/)
      expect(df.at("subfield[@code='d']")).to have_inner_text(/#{name['dates']}/)
      expect(df.at("subfield[@code='q']")).to have_inner_text(/#{name['fuller_form']}/)
      expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
      expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
      expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)
    end

    it "agent has no authority_id, it should not create a subfield $0" do
      name = @agents[7]['names'][0]
      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')
      df = @marcs[0].at("datafield[@tag='700']/subfield[@code='a'][text()='#{name_string}']")
      parent_node = df.parent
      expect(parent_node.at("subfield[@code='0']")).to be_nil
    end

    it "look to $v, $x, $y, and $z subdivisions when determining whether to export $0" do
      df = @marcs[0].at("datafield[@tag='600']")

      sfs = []
      ['v', 'x', 'y', 'z'].each do |sf|
        sfs << df.at("subfield[@code='#{sf}']")
      end

      # If these subfields are present, don't export $0
      if sfs.compact.count > 0
        expect(df.at("subfield[@code='0']")).to be_nil
      # If not present, do export $0
      else
        expect(df.at("subfield[@code='0']")).not_to be_nil
      end
    end

    it "should add required punctuation to 100 tag agent-person subfields" do
      name = @agents[0]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[0].at("datafield[@tag='100'][@ind1='#{inverted}'][@ind2=' ']")

      b_text = df.at("subfield[@code='b']").text
      c_text = df.at("subfield[@code='c']").text
      d_text = df.at("subfield[@code='d']").text
      g_text = df.at("subfield[@code='g']").text
      q_text = df.at("subfield[@code='q']").text

      unless c_text.nil? || c_text.empty?
        expect(b_text[-1]).to eq(",")
      end

      unless d_text.nil? || d_text.empty?
        expect(c_text[-1]).to eq(",")
      end

      expect(g_text =~ /\(.*\)/).not_to be_nil
      expect(q_text =~ /\(.*\)/).not_to be_nil
    end


    it "maps the first creator to df[@tag='110'] when it's a corp" do
      name = @agents[1]['names'][0]

      df = @marcs[1].at("datafield[@tag='110'][@ind1='2'][@ind2=' ']")
      resource = @resources[1]['linked_agents'].select { |r| r['role'] == 'creator' }.first

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name['primary_name']}/)
      subfield_b = df.at("subfield[@code='b']")
      if !subfield_b.nil?
        expect(subfield_b).to have_inner_text(/#{name['subordinate_name_1']}/)
      end
      expect(df.at("subfield[@code='n']")).to have_inner_text(/#{name['number']}/)
      expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
      expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
      expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)
    end


    it "maps the first creator to df[@tag='100'] when it's a family" do
      name = @agents[2]['names'][0]

      df = @marcs[2].at("datafield[@tag='100'][@ind1='3'][@ind2=' ']")
      resource = @resources[2]['linked_agents'].select { |r| r['role'] == 'creator' && r['ref'].include?('families')}.first

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name['family_name']}/)
      expect(df.at("subfield[@code='c']")).to have_inner_text(/#{name['qualifier']}/)
      expect(df.at("subfield[@code='d']")).to have_inner_text(/#{name['dates']}/)
      expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
      expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
      expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)
    end


    it "maps subject to 600 when it's a person" do
      name = @agents[0]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      ind2 = source_to_code(name['source'])

      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[1].at("datafield[@tag='600'][@ind1='#{inverted}'][@ind2='#{ind2}']")
      resource = @resources[1]['linked_agents'].select { |r| r['role'] == 'subject' }.first

      sf_v = df.at("subfield[@code='v']")
      sf_x = df.at("subfield[@code='x']")
      sf_y = df.at("subfield[@code='y']")
      sf_z = df.at("subfield[@code='z']")

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name_string}/)
      expect(df.at("subfield[@code='b']")).to have_inner_text(/#{name['number']}/)
      expect(df.at("subfield[@code='c']")).to have_inner_text(/#{%w(prefix title suffix).map {|p| name[p]}.compact.join(', ')}/)
      expect(df.at("subfield[@code='d']")).to have_inner_text(/#{name['dates']}/)

      if [sf_v, sf_x, sf_y, sf_z].all? { |sf| sf.nil? }
        expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
      end

      expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
      expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)

      if ind2 == '7'
        expect(df.at("subfield[@code='2']")).to have_inner_text(/#{name['source']}/)
      end
    end

    it "should add required punctuation to 600 tag agent-person subfields" do
      name = @agents[0]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      ind2 = source_to_code(name['source'])

      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[1].at("datafield[@tag='600'][@ind1='#{inverted}'][@ind2='#{ind2}']")

      b_text = df.at("subfield[@code='b']").text
      c_text = df.at("subfield[@code='c']").text
      d_text = df.at("subfield[@code='d']").text
      g_text = df.at("subfield[@code='g']").text
      q_text = df.at("subfield[@code='q']").text

      unless c_text.nil? || c_text.empty?
        expect(b_text[-1]).to eq(",")
      end

      unless d_text.nil? || d_text.empty?
        expect(c_text[-1]).to eq(",")
      end

      expect(g_text =~ /\(.*\)/).not_to be_nil
      expect(q_text =~ /\(.*\)/).not_to be_nil
    end


    it "maps subject agent to df[@tag='610'] when it's a corp" do
       name = @agents[1]['names'][0]
       ind2 = source_to_code(name['source'])

       df = @marcs[0].at("datafield[@tag='610'][@ind1='2'][@ind2='#{ind2}']")
       resource = @resources[0]['linked_agents'].select { |r| r['role'] == 'subject' }.first

       sf_v = df.at("subfield[@code='v']")
       sf_x = df.at("subfield[@code='x']")
       sf_y = df.at("subfield[@code='y']")
       sf_z = df.at("subfield[@code='z']")

       expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name['primary_name']}/)
       subfield_b = df.at("subfield[@code='b']")
       if !subfield_b.nil?
         expect(subfield_b).to have_inner_text(/#{name['subordinate_name_1']}/)
       end
       expect(df.at("subfield[@code='n']")).to have_inner_text(/#{name['number']}/)

       if [sf_v, sf_x, sf_y, sf_z].all? { |sf| sf.nil? }
         expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
       end

       expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
       expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)

       if ind2 == '7'
         expect(df.at("subfield[@code='2']")).to have_inner_text(/#{name['source']}/)
       end
     end

    it "should add required punctuation to 610 tag agent-corp subfields" do
      name = @agents[1]['names'][0]
      ind2 = source_to_code(name['source'])

      df = @marcs[0].at("datafield[@tag='610'][@ind1='2'][@ind2='#{ind2}']")

      a_text = df.at("subfield[@code='a']").text
      b_text = df.at("subfield[@code='b']").text
      e_text = df.at("subfield[@code='e']").text
      n_text = df.at("subfield[@code='n']").text

      if b_text.nil?
        expect(a_text[-1]).to eq(",")
      elsif !b_text.nil?
        expect(a_text[-1]).to eq(".")
      end

      expect(e_text[-1]).to eq(",")
      expect(n_text =~ /\(.*\)/).not_to be_nil
    end

    it "does not add punctuation to 610 a when followed by any subject subfield" do
      name = @agents[8]['names'][0]['primary_name']

      df = @marcs[1].at("datafield[@tag='610']")

      sf_a = df.at("subfield[@code='a']")
      sf_t = df.at("subfield[@code='t']")
      sf_v = df.at("subfield[@code='v']")
      sf_x = df.at("subfield[@code='x']")
      sf_y = df.at("subfield[@code='y']")
      sf_z = df.at("subfield[@code='z']")

      if ![sf_v, sf_x, sf_y, sf_z].all? { |sf| sf.nil? } && sf_t.nil?
        expect(sf_a).to have_inner_text(/#{name}/)
        expect(sf_a.text[-1]).not_to eq('.')
      else
        expect(sf_a.text[-1]).to eq('.')
      end
    end


    it "maps subject agent to df[@tag='600'] when it's a family" do
      name = @agents[2]['names'][0]
      ind2 = source_to_code(name['source'])

      df = @marcs[0].at("datafield[@tag='600'][@ind1='3'][@ind2='#{ind2}']")
      resource = @resources[0]['linked_agents'].select { |r| r['role'] == 'subject' && r['ref'].include?('families')}.first

      sf_v = df.at("subfield[@code='v']")
      sf_x = df.at("subfield[@code='x']")
      sf_y = df.at("subfield[@code='y']")
      sf_z = df.at("subfield[@code='z']")

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name['family_name']}/)
      expect(df.at("subfield[@code='c']")).to have_inner_text(/#{name['qualifier']}/)
      expect(df.at("subfield[@code='d']")).to have_inner_text(/#{name['dates']}/)

      if [sf_v, sf_x, sf_y, sf_z].all? { |sf| sf.nil? }
        expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
      end

      expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
      expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)

      if ind2 == '7'
        expect(df.at("subfield[@code='2']")).to have_inner_text(/#{name['source']}/)
      end
    end

    it "should add required punctuation to 600 tag agent-family subfields" do
      name = @agents[2]['names'][0]
      ind2 = source_to_code(name['source'])

      df = @marcs[0].at("datafield[@tag='600'][@ind1='3'][@ind2='#{ind2}']")

      a_text = df.at("subfield[@code='a']").text
      d_text = df.at("subfield[@code='d']").text
      c_text = df.at("subfield[@code='c']").text
      e_text = df.at("subfield[@code='e']").text

      expect(a_text[-1]).to eq(",")
      expect(d_text[-1]).to eq(",")
      expect(c_text[-1]).to eq(",")
    end


    it "maps the second creator to df[@tag='700'] when it's a person" do
      name = @agents[3]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[1].at("datafield[@tag='700'][@ind1='#{inverted}'][@ind2=' ']")
      resource = @resources[1]['linked_agents'].select { |r| r['role'] == 'creator' }[1]

      expect(df.at("subfield[@code='a']")).to have_inner_text(/#{name_string}/)
      expect(df.at("subfield[@code='b']")).to have_inner_text(/#{name['number']}/)
      expect(df.at("subfield[@code='c']")).to have_inner_text(/#{%w(prefix title suffix).map {|p| name[p]}.compact.join(', ')}/)
      expect(df.at("subfield[@code='d']")).to have_inner_text(/#{name['dates']}/)
      expect(df.at("subfield[@code='0']")).to have_inner_text(/#{name['authority_id']}/)
      expect(df.at("subfield[@code='4']")).to have_inner_text(/#{resource['relator']}/)
      expect(df.at("subfield[@code='e']")).to have_inner_text(/#{(I18n.t("enumerations.linked_agent_archival_record_relators.#{resource['relator']}"))}/)
    end

    it "should add required punctuation to 700 tag agent-person subfields" do
      name = @agents[3]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'
      name_string = %w(primary_ rest_of_).map {|p| name["#{p}name"]}.reject {|n| n.nil? || n.empty?}.join(name['name_order'] == 'direct' ? ' ' : ', ')

      df = @marcs[1].at("datafield[@tag='700'][@ind1='#{inverted}'][@ind2=' ']")

      b_text = df.at("subfield[@code='b']").text
      q_text = df.at("subfield[@code='q']").text
      c_text = df.at("subfield[@code='c']").text
      d_text = df.at("subfield[@code='d']").text
      g_text = df.at("subfield[@code='g']").text


      unless c_text.nil? || c_text.empty?
        expect(b_text[-1]).to eq(",")
      end

      unless d_text.nil? || d_text.empty?
        expect(c_text[-1]).to eq(",")
      end

      expect(g_text =~ /\(.*\)/).not_to be_nil
      expect(q_text =~ /\(.*\)/).not_to be_nil
    end

    # opposite case of spec found on line 143
    it "245 tag: sets first indicator to 1 if the resource has an creator" do
      expect(@marcs[0]).to have_tag "marc:datafield[@tag='245' and @ind1='1']"
    end

    it "stores qualifier in $c for secondary family creators " do
      name = @agents[6]['names'][0]
      inverted = name['name_order'] == 'direct' ? '0' : '1'

      expect(@marcs[0].xpath("//marc:datafield[@tag='700']/marc:subfield[@code='c'][contains(text(), '#{name['qualifier']}')]").length).to eq(1)
    end

    it "creates multiple 700 tags for multiple owner agents" do
      # 4 owner agents are linked above in before block in line 373, @agents

      expect(@marcs[0].xpath("//marc:datafield[@tag='700']").length).to eq(5)
    end
  end

  describe "note mappings" do

    let(:note_types) {
      %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial arrangement fileplan accessrestrict abstract scopecontent prefercite acqinfo bibliography index altformavail originalsloc userestrict legalstatus relatedmaterial custodhist appraisal accruals bioghist otherfindaid )
    }

    before(:all) do
      as_test_user('admin', true) do

        @resource = create(:json_resource,
                           :notes => full_note_set(true),
                           :publish => true)

        @marc = get_marc(@resource)

        raise Sequel::Rollback
      end
    end

    it "maps notes of type (odd|dimensions|physdesc|materialspec|physloc|phystech|physfacet|processinfo|separatedmaterial) to df 500, sf a" do
      xml_content = @marc.df('500', ' ', ' ').sf_t('a')
      types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial)
      notes = @resource.notes.select {|n| types.include?(n['type'])}
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
        expect(xml_content).to include(string)
      end
    end


    it "maps notes of type 'accessrestrict' to df 506, sf a" do
      note_test(@resource, @marc, %w(accessrestrict), ['506', ' ', ' '], 'a')
    end


    it "maps notes of type 'otherfindaid' to df 555, sf a" do
      note_test(@resource, @marc, %w(otherfindaid), ['555', '0', ' '], 'a')
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


    it "maps notes of type 'bibliography' to df 581 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(note_bibliography), ['581', ' ', ' '], 'a')
    end


    it "maps notes of type 'bioghist' to df 545 (' ', ' '), sf a" do
      note_test(@resource, @marc, %w(bioghist), ['545', ' ', ' '], 'a')
    end


    it "maps resource.ead_location to df 856 ('4', '2'), sf u" do
      df = @marc.df('856', '4', '2')
      expect(df.sf_t('u')).to include(@resource.ead_location)
      expect(df.sf_t('z')).to include("Finding aid online:")
    end

    describe 'automatically include finding aids in marc exports enabled' do
      before(:all) do
        AppConfig[:include_pui_finding_aid_urls_in_marc_exports] = true
      end

      it "automatically includes PUI link in 856 $u" do
        resource = create(:json_resource, :ead_location => nil, :publish => true)
        marc = get_marc(resource)

        df = marc.df('856', '4', '2')

        matches_uri      = df.sf_t('u') =~ /#{resource['uri']}/
        matches_pui_link = df.sf_t('u') =~ /#{AppConfig[:public_url]}/

        expect(matches_uri != nil || matches_pui_link != nil).to eq(true)
      end
    end

    describe 'slugs and automatically include finding aids in marc exports enabled' do
      before(:all) do
        AppConfig[:include_pui_finding_aid_urls_in_marc_exports] = true
        AppConfig[:use_human_readable_urls] = true
        AppConfig[:use_slug_finding_aid_urls_in_marc_exports] = true
      end

      it "automatically includes slugged PUI link in 856 $u" do
        resource = create(:json_resource, :ead_location => nil, :publish => true, :slug => "slugged_url")
        marc = get_marc(resource)

        df = marc.df('856', '4', '2')
        df.sf_t('u').should match(/slugged_url/)
      end
    end

    describe 'ARKs enabled' do

      before(:all) do
        AppConfig[:arks_enabled] = true
      end

      it "maps ARK url to df 856 ('4', '2'), sf u if ead_location is blank and ARKs are enabled" do
        resource = create(:json_resource,
                          :ead_location => nil)
        marc = get_marc(resource)

        ark_url = resource['ark_name']['current']

        df = marc.df('856', '4', '2')
        df.sf_t('u').should eq(ark_url)
        df.sf_t('z').should eq("Archival Resource Key:")
        resource.delete
      end

    end

    describe 'ARKs disabled' do

      before(:all) do
        AppConfig[:arks_enabled] = false
      end

      it "does not map ARK url to df 856 ('4', '2'), sf u if ead_location is blank and ARKs are disabled" do
        resource = create(:json_resource,
                          :ead_location => nil)
        marc = get_marc(resource)

        expect(resource['ark_name']).to be_nil

        df = marc.df('856', '4', '2')
        expect(df.sf_t('u')).to_not include("ark:/")
        resource.delete
      end

    end

    it "maps resource.finding_aid_note to df 555 ('0', ' '), sf u" do
      pending "should this test be removed?"
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

    it "5XX tags should end in punctuation" do
      types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial arrangement fileplan accessrestrict abstract scopecontent prefercite acqinfo bibliography index altformavail originalsloc userestrict legalstatus relatedmaterial custodhist appraisal accruals bioghist otherfindaid )
      notes = @resource.notes.select {|n| types.include?(n['type'])}

      notes.each do |note|
        content = note_content(note)
        expect(@marc.to_xml).to match(/#{content + "."}/)
      end
    end
  end

  describe "notes: include unpublished flag" do
    before(:all) do
      as_test_user('admin', true) do
        @resource = create(:json_resource,
                           :notes => full_note_set(false))

        @marc_unpub_incl   = get_marc(@resource, true)
        @marc_unpub_unincl = get_marc(@resource, false)

        raise Sequel::Rollback
      end
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
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{506}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{524}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{535}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{540}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{541}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{544}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{545}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{561}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{583}']").length > 0).to be_truthy
      expect(@marc_unpub_incl.xpath("//marc:datafield[@tag = '#{584}']").length > 0).to be_truthy
    end

  end

  describe "notes: inherit publish from parent" do
    before(:all) do
      as_test_user('admin', true) do
        @resource = create(:json_resource,
                           :notes => full_note_set(true),
                           :publish => false)

        @marc_unpub_unincl = get_marc(@resource, false)

        raise Sequel::Rollback
      end
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
      as_test_user('admin', true) do
        @resource = create(:json_resource)
        @org_code = JSONModel(:repository).find($repo_id).org_code

        @marc = get_marc(@resource)

        raise Sequel::Rollback
      end
    end

    it "maps org_code to 049 tag" do
      expect(@marc.at("datafield[@tag='049'][@ind1=' '][@ind2=' ']/subfield[@code='a']")).to have_inner_text(@org_code)
    end
  end
end
