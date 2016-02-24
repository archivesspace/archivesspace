require_relative 'export_spec_helper'

describe 'EAC Export' do

  describe "nameEntryParallel tag" do
    it "wraps two or more name entries in a nameEntryParallel tag" do
      rec = create(:json_agent_family,
                    :names => [ 
                               build(:json_name_family),
                               build(:json_name_family)
                              ]
                    )
      eac = get_eac(rec)

      eac.should have_tag("identity/nameEntryParallel")
      eac.should_not have_tag("identity/nameEntry")
    end


    it "doesn't wrap one name entry in a nameEntryParallel tag" do
      rec = create(:json_agent_family,
                    :names => [ 
                               build(:json_name_family),
                              ]
                    )
      eac = get_eac(rec)

      eac.should have_tag("identity/nameEntry")
      eac.should_not have_tag("identity/nameEntryParallel")
    end
  end


  describe 'agent_person' do
    before(:all) do
      @rec = create(:json_agent_person, 
                    :names => [
                               build(:json_name_person, 
                                     :prefix => 'abcdefg'
                                     ), 
                               build(:json_name_person)
                              ]
                    )

      @eac = get_eac(@rec)
    end

    after(:all) do
      @rec.delete
    end


    it "exports EAC with the correct namespaces" do
      @eac.should have_namespaces({
        "xmlns"=> "urn:isbn:1-931666-33-4",
        "xmlns:html" => "http://www.w3.org/1999/xhtml",
        "xmlns:xlink" => "http://www.w3.org/1999/xlink",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      })
    end


    it "maps name.rules to authorizedForm" do
      rule1 = @rec.names[0]['rules']
      rule2 = @rec.names[1]['rules']
      @eac.should have_tag('nameEntry[1]/authorizedForm' => rule1)
      @eac.should have_tag('nameEntry[2]/authorizedForm' => rule2)
    end


    it "maps name.source to authorizedForm" do
      source1 = @rec.names[0]['source']
      source2 = @rec.names[1]['source']
      @eac.should have_tag('nameEntry[1]/authorizedForm' => source1)
      @eac.should have_tag('nameEntry[2]/authorizedForm' => source2)
    end


    it "maps name.prefix to nameEntry/part[@localType='prefix']" do
      val = @rec.names[0]['prefix']
      tag = "nameEntry[1]/part[@localType='prefix']"
      if val
        @eac.should have_tag(tag => val)
      else
        @eac.should_not have_tag(tag)
      end
    end


    it "maps name.title to nameEntry/part[@localType='title']" do
      val = @rec.names[0]['title']
      tag = "nameEntry[1]/part[@localType='title']"
      if val        
        @eac.should have_tag(tag => val)
      else
        @eac.should_not have_tag(tag)
      end
    end


    it "maps name.primary_name to nameEntry/part[@localType='surname']" do
      val = @rec.names[0]['primary_name']
      tag = "nameEntry[1]/part[@localType='surname']"
      @eac.should have_tag(tag => val)
    end


    it "maps name.rest_of_name to nameEntry/part[@localType='forename']" do
      val = @rec.names[0]['rest_of_name']
      tag = "nameEntry[1]/part[@localType='forename']"
      if val
        @eac.should have_tag(tag => val)
      else
        @eac.should_not have_tag(tag)
      end
    end


    it "maps name.suffix to nameEntry/part[@localType='suffix']" do
      val = @rec.names[0]['suffix']
      tag = "nameEntry[1]/part[@localType='suffix']"
      if val
        @eac.should have_tag(tag => val)
      else
        @eac.should_not have_tag(tag)
      end
    end


    it "maps name.number to nameEntry/part[@localType='number']" do
      val = @rec.names[0]['number']
      tag = "nameEntry[1]/part[@localType='number']"
      @eac.should have_tag(tag => val)
    end


    it "maps name.fuller_form to nameEntry/part[@localType='fullerForm']" do
      val = @rec.names[0]['fuller_form']
      tag = "nameEntry[1]/part[@localType='fullerForm']"
      @eac.should have_tag(tag => val)
    end


    it "maps name qualifier to nameEntry/part[@localType='qualifier']" do
      val = @rec.names[0]['qualifier']
      tag = "nameEntry[1]/part[@localType='qualifier']"
      @eac.should have_tag(tag => val)
    end


    it "maps agent_person records to EAC docs with entityType = person" do
      @eac.should have_tag('entityType' => 'person')
    end

  end

  describe "agent_corporate_entity" do

    before(:all) do
      date1 = build(:json_date,
                    :date_type => 'inclusive',
                    :begin => '2010-01-01',
                    :end => '2011-01-01'
                    )

      date2 = build(:json_date,
                    :date_type => 'inclusive',
                    :begin => '2012-01-01',
                    :end => '2013-01-01'
                    )

      date3 = build(:json_date,
                    :date_type => 'single',
                    :begin => '2014-01-01',
                    )

      @rec = create(:json_agent_corporate_entity, 
                    :names => [
                               build(:json_name_corporate_entity, 
                                     :use_dates => [
                                                    date1,
                                                    date2,
                                                    date3
                                                    ]
                                     ),
                               build(:json_name_corporate_entity)
                              ]
                    )

      @eac = get_eac(@rec)
    end

    after(:all) do
      @rec.delete
    end

    it "maps name.primary_name to nameEntry/part[@localType='primaryPart']" do
      val = @rec.names[0]['primary_name']
      tag = "nameEntry[1]/part[@localType='primaryPart']"
      @eac.should have_tag(tag => val)
    end


    it "maps name.subordinate_name_1 to nameEntry/part[@localType='secondaryPart']" do
      val = @rec.names[0]['subordinate_name_1']
      tag = "nameEntry[1]/part[@localType='secondaryPart']"
      @eac.should have_tag(tag => val)
    end


    it "maps name.subordinate_name_2 to nameEntry/part[@localType='tertiaryPart']" do
      val = @rec.names[0]['subordinate_name_2']
      tag = "nameEntry[1]/part[@localType='tertiaryPart']"
      @eac.should have_tag(tag => val)
    end


    it "maps name.number to nameEntry/part[@localType='number']" do
      val = @rec.names[0]['number']
      tag = "nameEntry[1]/part[@localType='number']"
      @eac.should have_tag(tag => val)
    end


    it "maps name qualifier to nameEntry/part[@localType='qualifier']" do
      val = @rec.names[0]['qualifier']
      tag = "nameEntry[1]/part[@localType='qualifier']"
      @eac.should have_tag(tag => val)
    end


    it "maps each name.use_dates[] to a useDates tag" do
      @eac.should have_tag("nameEntry[1]/useDates[3]")
      @eac.should_not have_tag("nameEntry[1]/useDates[4]")
    end


    it "creates a from- and to-Date for 'bulk' dates" do
         from = @rec.names[0]['use_dates'][0]['begin']
         to = @rec.names[0]['use_dates'][0]['end']
   
         @eac.should have_tag("nameEntry[1]/useDates[1]/dateRange/fromDate[@standardDate=\"#{from}\"]" => "#{from}")
         @eac.should have_tag("nameEntry[1]/useDates[1]/dateRange/toDate[@standardDate=\"#{to}\"]" => "#{to}")
    end


    it "creates a from- and to-Date for 'inclusive' dates" do
      from = @rec.names[0]['use_dates'][1]['begin']
      to = @rec.names[0]['use_dates'][1]['end']

      @eac.should have_tag("nameEntry[1]/useDates[2]/dateRange/fromDate[@standardDate=\"#{from}\"]" => "#{from}")
      @eac.should have_tag("nameEntry[1]/useDates[2]/dateRange/toDate[@standardDate=\"#{to}\"]" => "#{to}")
    end


    it "does not create a from- or to-Date 'single' dates" do
      @eac.should_not have_tag("nameEntry[1]/useDates[3]/dateRange/fromDate")
      @eac.should_not have_tag("nameEntry[1]/useDates[3]/dateRange/toDate")
    end


    it "creates a date tag for 'single' dates" do
      @eac.should have_tag("nameEntry[1]/useDates[3]/dateRange/date" => @rec.names[0]['use_dates'][2]['begin'])
    end

  end

  describe "agent_family" do

    before(:all) do
      @repo = create(:json_repo)
      $old_repo_id = $repo_id
      $repo_id = @repo.id
      JSONModel.set_repository($repo_id)
      
      @rec = create(:json_agent_family, 
                    :names => [
                               build(:json_name_family), 
                               build(:json_name_family)
                              ]
                    )

      @eac = get_eac(@rec)

      # puts "SOURCE: #{@rec.inspect}\n"
      # puts "RESULT: #{@eac.to_xml}\n"
    end

    after(:all) do
      @rec.delete
    end

    it "maps name.prefix to nameEntry/part[@localType='prefix']" do
      val = @rec.names[0]['prefix']
      tag = "nameEntry[1]/part[@localType='prefix']"
      if val
        @eac.should have_tag(tag => val)
      else
        @eac.should_not have_tag(tag)
      end
    end


    it "maps name.family_name to nameEntry/part[@localType='familyName']" do
      val = @rec.names[0]['family_name']
      tag = "nameEntry[1]/part[@localType='familyName']"
      if val
        @eac.should have_tag(tag => val)
      else
        @eac.should_not have_tag(tag)
      end
    end
  end


  describe "dates of existence" do
    before(:all) do
      @rec = create(:json_agent_person,
                    :dates_of_existence => [
                                            build(:json_date,
                                                  :date_type => 'bulk',
                                                  :label => 'existence'),
                                            build(:json_date,
                                                  :label => 'existence')
                                            ]
                    )
      @eac = get_eac(@rec)
    end


    after(:all) do
      @rec.delete
    end

    it "creates an existDates tag for the first date of existence" do
      @eac.should have_tag("description/existDates[1]")
      @eac.should_not have_tag("description/existDates[2]")
    end


    it "maps date.expression to dateRange" do
      @eac.should have_tag("description/existDates/dateRange" =>
                           @rec.dates_of_existence[0]['expression'])
    end


    it "maps date.begin to fromDate" do
      @eac.should have_tag("existDates/dateRange[2]/fromDate[@standardDate=\"#{@rec.dates_of_existence[0]['begin']}\"]" =>
                           @rec.dates_of_existence[0]['begin'])
    end


    it "maps date.end to toDate" do
      @eac.should have_tag("existDates/dateRange[2]/toDate[@standardDate=\"#{@rec.dates_of_existence[0]['end']}\"]" =>
                           @rec.dates_of_existence[0]['end'])
    end
  end


  describe "biographical / historical notes" do
    before(:all) do
      subnotes = [
                  :note_abstract,
                  :note_chronology,
                  :note_citation,
                  :note_orderedlist,
                  :note_definedlist,
                  :note_text,
                  :note_outline
                 ]
        

      @rec = create(:json_agent_person,
                    :notes => [ build(:json_note_bioghist,
                                      :subnotes => subnotes.map {|type|
                                        build("json_#{type.to_s}".intern,
                                              :publish => true)
                                      },
                                      :publish => true
                                      ) 
                              ]
                    )
      @eac = get_eac(@rec)

      @subnotes = Hash[subnotes.map{|type| [type, get_subnotes_by_type(@rec.notes[0], type.to_s)[0]] } ]

      # puts @rec.inspect
      # puts @eac.to_xml
    end

    after(:all) do
      @rec.delete
    end


    it "creates a biogHist tag for each note" do
      rec = create(:json_agent_person,
                   :notes => [1,2].map{ build(:json_note_bioghist, :publish => true) }
                   )
      eac = get_eac(rec)

      eac.should have_tag("biogHist[2]")
    end


    it "ignores un-published notes" do
      rec = create(:json_agent_person,
                   :notes => [ build(:json_note_bioghist,
                                   :publish => false) ]
                   )

      eac = get_eac(rec)

      eac.should_not have_tag("biogHist")
    end


    it "maps 'abstract' subnotes to abstract tags" do
      @eac.should have_tag("biogHist/abstract" => 
                           @subnotes[:note_abstract]['content'].join('--'))
    end


    it "maps 'citation' subnotes to 'citation' tags" do
      xlink_values = @subnotes[:note_citation]['xlink']
      citation_text = @subnotes[:note_citation]['content'].join('--')

      @eac.should have_tag("biogHist/citation[@xlink:actuate=\"#{xlink_values['actuate']}\"]") 
      @eac.should have_tag("biogHist/citation[@xlink:arcrole='#{xlink_values['arcrole']}']")
      @eac.should have_tag("biogHist/citation[@xlink:href='#{xlink_values['href']}']")
      @eac.should have_tag("biogHist/citation[@xlink:role='#{xlink_values['role']}']")
      @eac.should have_tag("biogHist/citation[@xlink:show='#{xlink_values['show']}']")
      @eac.should have_tag("biogHist/citation[@xlink:title='#{xlink_values['title']}']")
 
      @eac.should have_tag("biogHist/citation" => citation_text)
    end


    it "maps 'definedlist' subnotes to 'list[@localType=\"defined:{title}\"]' tags" do
      list_title = @subnotes[:note_definedlist]['title']
      list_items = @subnotes[:note_definedlist]['items']

      @eac.should have_tag("biogHist/list[@localType='defined:#{list_title}']/item[#{list_items.count}]")
      @eac.should_not have_tag("biogHist/list[@localType='defined:#{list_title}']/item[#{list_items.count + 1}]")
      @eac.should have_tag("biogHist/list/item[@localType='#{list_items.last['label']}']" => list_items.last['value'])
    end


    it "maps 'orderedlist' subnotes to 'list[@localType=\"ordered:{title}\"]' tags" do
      list_title = @subnotes[:note_orderedlist]['title']
      list_items = @subnotes[:note_orderedlist]['items']
      enumeration = @subnotes[:note_orderedlist]['enumeration']

      @eac.should have_tag("biogHist/list[@localType='ordered:#{list_title}']/item[#{list_items.count}]")
      @eac.should_not have_tag("biogHist/list[@localType='ordered:#{list_title}']/item[#{list_items.count + 1}]")
      @eac.should have_tag("biogHist/list/item[@localType='#{enumeration}']" => list_items.last)
    end


    it "maps 'chronology' subnotes to 'chronList' tags" do
      chron_title = @subnotes[:note_chronology]['title']

      if chron_title
        @eac.should have_tag("biogHist/chronList[@localType='#{chron_title}']")
      else
        @eac.should_not have_tag("biogHist/chronList[@localType]")
        @eac.should have_tag("biogHist/chronList")
      end
    end


    it "maps every 'event' of every 'item' in a 'chronology' to a 'chronitem' tag" do
      events = @subnotes[:note_chronology]['items'].map{|i| i['events'].map{|e| [i['event_date'], e] } }.flatten(1)

      @eac.should have_tag("chronList/chronItem[#{events.count}]")
      @eac.should_not have_tag("chronList/chronItem[#{events.count + 1}]")
    end


    it "maps 'event_date' of an 'item' to each 'chronItem/@standardDate'" do
      events = @subnotes[:note_chronology]['items'].map{|i| i['events'].map{|e| [i['event_date'], e] } }.flatten(1)

      events.each do |event| # date, event pair
        if event[0] && event[0].length
          @eac.should have_tag("chronList/chronItem[@standardDate='#{event[0]}']/event" => event[1])
        else
          @eac.should have_tag("chronList/chronItem/event" => event[1])
          @eac.should_not have_tag("chronList/chronItem[@standardDate]/event" => event[1])
        end
      end
    end


    it "maps 'outline' subnotes to 'outline' tags" do
      rec = create(:json_agent_person,
                   :notes => [ build(:json_note_bioghist, :publish => true,
                                     :subnotes => [build(:json_note_outline,
                                                         :levels => (0..rand(3)).map { build(:json_note_outline_level,
                                                                                             :items => (0..rand(3)).map { [true, false].sample ? build(:json_note_outline_level) : generate(:alphanumstr) }
                                                                                             ) }
                                                         ),
                                                   build(:json_note_text),
                                                  ]
                                     )
                             ]
                 )
      eac = get_eac(rec)

      outline = get_subnotes_by_type(rec.notes[0], 'note_outline')[0]
      eac.should have_tag("outline/level[#{outline['levels'].count}]")
      eac.should_not have_tag("outline/level[#{outline['levels'].count + 1}]")

      outline['levels'].sample['items'].each do |item|
        if item.is_a?(String)
          eac.should have_tag("outline/level/item" => item)
        else
          eac.should have_tag("outline/level/level/item" => item['items'][0])
        end
      end
    end
  end

  describe "Relations" do
    before(:each) do
      @repo = create(:json_repo)
      $old_repo_id = $repo_id
      $repo_id = @repo.id

      JSONModel.set_repository($repo_id)

      @rec = create(:json_agent_person,
                    :external_documents => [
                                            build(:json_external_document),
                                            build(:json_external_document,
                                                  :location => "not a url")
                                           ]
                    )
      @resource, @digital_object = [:json_resource, :json_digital_object].map {|type| 
        create(type,
               :linked_agents => [{
                 'role' => %w(creator subject).sample,
                 'ref' => @rec.uri
               }])
      }

      @resource_component = create(:json_archival_object,
                                   :resource => {'ref' => @resource.uri},
                                   :linked_agents => [{
                                                        'role' => 'subject',
                                                        'ref' => @rec.uri
                                                      }])

      @digital_object_component = create(:json_digital_object_component,
                                         :digital_object => {'ref' => @digital_object.uri},
                                         :linked_agents => [{
                                                              'role' => 'subject',
                                                              'ref' => @rec.uri
                                                            }])


      @relationship = JSONModel(:agent_relationship_parentchild).new
      @relationship.relator = "is_child_of"
      @relationship.ref = @rec.uri

      @linked_agent = create(:json_agent_person,
                             :related_agents => [@relationship.to_hash]
                             )

      @eac = get_eac(@rec)

    end

    after(:each) do
      $repo_id = $old_repo_id
      JSONModel.set_repository($repo_id)
    end

    it "maps related agents to cpfRelation" do
      @eac.should have_tag("relations/cpfRelation[@cpfRelationType='is_parent_of'][@xlink:href='#{@linked_agent.uri}']/relationEntry" =>
@linked_agent.names[0]['primary_name'])
    end


    it "maps related resources and components to resourceRelation" do
      role = @resource.linked_agents[0]['role'] + "Of"
      @eac.should have_tag("relations/resourceRelation[@resourceRelationType='#{role}']/relationEntry" => @resource.title)
      @eac.should have_tag("relations/resourceRelation/relationEntry" => @resource_component.title)
    end


    it "maps related digital objects and components to resourceRelation" do
      role = @digital_object.linked_agents[0]['role'] + "Of"
      @eac.should have_tag("relations/resourceRelation[@resourceRelationType='#{role}']/relationEntry" => @digital_object.title)
      @eac.should have_tag("relations/resourceRelation/relationEntry" => @digital_object_component.title)
    end


    it "maps external documents to resourceRelation" do
      @eac.should have_tag("relations/resourceRelation[@resourceRelationType='other'][1]")
      # bad locations don't get exported
      @eac.should_not have_tag("relations/resourceRelation[@resourceRelationType='other'][2]")
    end
  end


  describe "maintenanceAgency" do

    it "maps the repository name and org code" do
      repo = create(:json_repo)

      JSONModel.set_repository(repo.id)

      rec = create(:json_agent_family)
      eac = get_eac(rec, repo.id)

      eac.should have_tag "control/maintenanceAgency/agencyCode" => repo.org_code
      eac.should have_tag "control/maintenanceAgency/agencyName" => repo.name
    end

  end

  # Ensure nil values don't mess things up, etc.
  describe "miscellaneous" do

    it "doesn't create any empty tags for dates missing expression" do
      rec = create(:json_agent_person,
                   :names => [build(:json_name_person,
                                    :use_dates => [
                                                   build(:json_date,
                                                         :expression => nil
                                                         )
                                                   ]
                                    )
                             ],
                   :dates_of_existence => [build(:json_date,
                                                 :label => 'existence',
                                                 :expression => nil
                                                 )
                                          ]
                   )
      eac = get_eac(rec)

      eac.should_not have_tag("dateRange" => "")
    end
  end

end
