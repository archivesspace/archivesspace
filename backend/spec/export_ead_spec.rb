require 'nokogiri'
require 'spec_helper'
require_relative 'export_spec_helper'

describe "EAD export mappings" do

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
                                     :persistent_id => "mixed_subnotes_tracer",
                                     :subnotes => [build(:json_note_text, { :publish => true,
                                                           :content => "note_text - The ship set ground on the shore of this uncharted desert isle"} ),
                                                   build(:json_note_text, { :publish => true,
                                                           :content => "<p id='whatisthisfoolishness' >note_text - With:</p>"}),
                                                   build(:json_note_definedlist,{  :publish => true, :title => "note_definedlist",
                                                           :items => [
                                                                      {:label => "First Mate", :value => "<persname encodinganalog='600$a' source='lcnaf'>Gilligan</persname>" },
                                                                      {:label => "Captain",:value => "The Skipper"},
                                                                      {:label => "Etc.", :value => "The Professor and Mary Ann" }
                                                                     ]
                                                         }),
                                                   build(:json_note_text,{   :content => "note_text - Here on Gillgian's Island", :publish => true}) ,
                                                  ]
                                   })

    @another_note_tracer = build("json_note_multipart", {
                              :type => 'bioghist',
                              :publish => true,
                              :persistent_id => "another_note_tracer",
                              :subnotes => [
                                            build(:json_note_chronology, {
                                                    :title => "my life story",
                                                    :items => [{'event_date' => "1900", 'events' => ["LIFE &amp; DEATH"]}]
                                                  }),
                                           ]
                            })


    resource = create(:json_resource,  :linked_agents => build_linked_agents(@agents),
                      :notes => build_archival_object_notes(10) + [@mixed_subnotes_tracer, @another_note_tracer],
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


  def doc(use_namespaces = false)
    use_namespaces ? @doc : @doc_nsless
  end


  def archival_object(index)
    @archival_objects.values[index]
  end

  before(:all) do

    as_test_user("admin") do
      DB.open(true) do
        load_export_fixtures
        @doc = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_unpublished=true&include_daos=true")


        @doc_nsless = Nokogiri::XML::Document.parse(@doc.to_xml)
        @doc_nsless.remove_namespaces!
        raise Sequel::Rollback
      end
    end


    @doc.errors.length.should == 0

    # if the word Nokogiri appears in the XML file, we'll assume something
    # has gone wrong
    @doc.to_xml.should_not include("Nokogiri")
    @doc.to_xml.should_not include("#&amp;")
    @doc.to_xml.should_not include("ASPACE EXPORT ERROR")
  end


  let(:repo) { JSONModel(:repository).find($repo_id) }


  # Examples used by resource and archival_objects
  shared_examples "archival object desc mappings" do
    it "maps {archival_object}.level to {desc_path}@level" do
      mt(object.level, desc_path, "level")
    end


    it "maps {archival_object}.other_level to {desc_path}@otherlevel" do
      mt(object.other_level, desc_path, "otherlevel")
    end


    it "maps {archival_object}.title to {desc_path}/did/unittitle" do
      mt(object.title, "#{desc_path}/did/unittitle", :markup)
    end


    it "maps {archival_object}.(id_[0-3]|component_id) to {desc_path}/did/unitid" do
      if !unitid_src.nil? && !unitid_src.empty?
        mt(unitid_src, "#{desc_path}/did/unitid")
      end
    end


    it "maps {archival_object}.language to {desc_path}/did/langmaterial/language" do
      data = object.language ? translate('enumerations.language_iso639_2', object.language) : nil
      code = object.language

      mt(data, "#{desc_path}/did/langmaterial/language")
      mt(code, "#{desc_path}/did/langmaterial/language", 'langcode')
    end


    describe "archdesc or component notes section: " do
      let(:archdesc_note_types) {
        %w(accruals appraisal arrangement bioghist accessrestrict userestrict custodhist altformavail originalsloc fileplan odd acqinfo otherfindaid phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial)
      }

      it "maps note content to {desc_path}/NOTE_TAG" do
        object.notes.select{|n| archdesc_note_types.include?(n['type'])}.each do |note|
          head_text = note['label'] ? note['label'] : translate('enumerations._note_types', note['type'])
          id = "aspace_" + note['persistent_id']
          content = Nokogiri::XML::DocumentFragment.parse(note_content(note)).inner_text
          path = "#{desc_path}/#{note['type']}"
          path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"

          if !note['persistent_id'].nil?
            mt(id, path, 'id')
          else
            mt(nil, path, 'id')
          end

          mt(head_text, "#{path}/head")
          regcontent = content.split(/\n\n|\r/).map { |c| ".*?[\r\n\n]*.*?#{c.strip}" }
          next if regcontent.empty?
          mt(/^.*?#{head_text}.*?[\r\n\n]*.*?#{regcontent}.*?$/m, "#{path}")
        end
      end
    end


    describe "bibliography and index notes section: " do
      let(:bibliographies) { object.notes.select {|n| n['type'] == 'bibliography'} }
      let(:indexes) { object.notes.select {|n| n['type'] == 'index'} }
      let(:index_item_type_map) {  {
          'corporate_entity'=> 'corpname',
          'genre_form'=> 'genreform',
          'name'=> 'name',
          'occupation'=> 'occupation',
          'person'=> 'persname',
          'subject'=> 'subject',
          'family'=> 'famname',
          'function'=> 'function',
          'geographic_name'=> 'geogname',
          'title'=> 'title'
        }
      }

      it "maps notes[].note_bibliography to {desc_path}/bibliography" do
        bibliographies.each do |note|
          head_text = note['label']
          id = "aspace_" + note['persistent_id']
          content = note_content(note)
          content.gsub!("<p>", "").gsub!("</p>", "").strip
          path = "bibliography"
          path += id ? "[@id='#{id}']" : "[p[contains(text(), #{content})]]"
          full_path = "#{desc_path}/#{path}"

          if !note['persistent_id'].nil?
            mt(id, full_path, 'id')
          else
            mt(nil, full_path, 'id')
          end
          mt(head_text, "#{full_path}/head")
          mt(content, "./#{path}/p/text()[contains('#{content}')]")

          note['items'].each_with_index do |item, i|
            mt(item, "#{full_path}/bibref[#{i+1}]")
          end
        end
      end


      it "maps notes[].note_index to {desc_path}/index" do
        indexes.each do |note|
          head_text = note['label']
          id = "aspace_" + note['persistent_id']
          content = note_content(note)
          path = "index"
          path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"
          full_path = "#{desc_path}/#{path}"
          if note['persistent_id']
            mt(id, full_path, 'id')
          else
            mt(nil, full_path, 'id')
          end

          mt(head_text, "#{full_path}/head")
          mt(content, "./#{path}/p/text()[contains( '#{content}')]")

          note['items'].each_with_index do |item, i|
            index_item_type_map.keys.should include(item['type'])
            item_path = "#{full_path}/indexentry[#{i+1}]"
            mt(item['value'], "#{item_path}/#{index_item_type_map[item['type']]}")
            mt(item['reference'], "#{item_path}/ref", 'target')
            mt(item['reference_text'], "#{item_path}/ref")
          end
        end
      end
    end


    describe "How mixed content notes are mapped >> " do
      let(:archdesc_note_types) {
        %w(accruals appraisal arrangement bioghist accessrestrict userestrict custodhist altformavail originalsloc fileplan odd acqinfo otherfindaid phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial)
      }
      let(:multis) { object.notes.select{|n| n['subnotes'] && (archdesc_note_types).include?(n['type']) } }

      let(:build_path) { Proc.new {|note|
          content = note_content(note)
          id = "aspace_" + note['persistent_id']
          path = "#{desc_path}/#{note['type']}"
          path += note['persistent_id'] ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"
        }
      }

      it "maps subnotes[].note_chronology to NOTE_PATH/chronlist" do
        multis.each do |note|
          chron_notes = get_subnotes_by_type(note, 'note_chronology')
          next if chron_notes.empty?

          path = build_path.call(note)

          chron_notes.each_with_index do |chron, i|
            chron_path = "#{path}/chronlist[#{i+1}]"
            mt(chron['title'], "#{chron_path}/head")

            chron['items'].each_with_index do |item, j|
              item_path = "#{chron_path}/chronitem[#{j+1}]"
              mt(item['event_date'], "#{item_path}/date")

              next unless item.has_key?('events')
              item['events'].each_with_index do |event, k|
                event_path = "#{item_path}/eventgrp/event[#{k+1}]"
                # Nokogiri 'helpfully' reads "&amp;" into "&" when it parses the doc
                mt(event.gsub("&amp;", "&"), event_path)
              end
            end
          end
        end
      end


      it "maps subnotes[].note_orderedlist to NOTE_PATH/list[@type='ordered']" do
        multis.each do |note|
          orderedlists = get_subnotes_by_type(note, 'note_orderedlist')
          next if orderedlists.empty?

          ppath = build_path.call(note)

          orderedlists.each_with_index do |ol, i|
            ol_path = "#{ppath}/list[@type='ordered'][#{i+1}]"

            mt(ol['enumeration'], ol_path, 'numeration')
            mt(ol['title'], "#{ol_path}/head")

            ol['items'].each_with_index do |item, j|
              mt(item, "#{ol_path}/item[#{j+1}]")
            end
          end
        end
      end


      it "maps subnotes[].note_definedlist to NOTE_PATH/list[@type='deflist']" do
        multis.each do |note|
          definedlists = get_subnotes_by_type(note, 'note_definedlist')
          next if definedlists.empty?

          ppath = build_path.call(note)

          definedlists.each_with_index do |dl, i|
            dl_path = "#{ppath}/list[@type='deflist'][#{i+1}]"

            mt(dl['title'], "#{dl_path}/head")
            dl['items'].each_with_index do |item, j|
              mt(item['label'], "#{dl_path}/defitem[#{j+1}]/label")
              mt(item['value'], "#{dl_path}/defitem[#{j+1}]/item",  :markup)
            end
          end
        end
      end

      it "ensures subnotes[] order is respected, even if subnotes are of mixed types" do

        path = "//bioghist[@id = 'aspace_#{@mixed_subnotes_tracer['persistent_id']}']"
        head_text = translate('enumerations._note_types',@mixed_subnotes_tracer['type'])

        mt(head_text, "#{path}/head")
        i = 2 # start at two since head is the first child
        @mixed_subnotes_tracer["subnotes"].each do |note|
          mt(/#{note["jsonmodel_type"]}/, "#{path}/*[text() != ''][#{i.to_s}]")
          i = i + 1
        end

      end


      it "doesn't double-escape '&amp;' in a chronitem event on export" do
        path = "//bioghist[@id = 'aspace_#{@another_note_tracer['persistent_id']}']/chronlist/chronitem/eventgrp/event"

        # we are really testing that the raw XML doesn't container '&amp;amp;'
        mt("LIFE & DEATH", path)
      end
    end

    describe "How {archival_object}.instances[].container data is mapped." do
      let(:containers) { object.instances.map {|i| i['container'] } }
      let(:instances) { object.instances.reject {|i| i['container'].nil? } }

      before(:each) do
        @count = 0
      end

      it "maps {archival_object}.instances[].container.type_{i} to {desc_path}/did/container@type" do
        instances.each do |inst|
          cont = inst['container']
          (1..3).each do |i|
            next unless cont.has_key?("type_#{i}") && cont.has_key?("indicator_#{i}")
            @count +=1
            data = cont["type_#{i}"]
            mt(data, "#{desc_path}/did/container[#{@count}]", "type")
          end
        end
      end


      it "maps {archival_object}.instances[].container.indicator_{i} to {desc_path}/did/container" do
        instances.each do |inst|
          cont = inst['container']
          (1..3).each do |i|
            next unless cont.has_key?("type_#{i}") && cont.has_key?("indicator_#{i}")
            @count +=1
            data = cont["indicator_#{i}"]
            mt(data, "#{desc_path}/did/container[#{@count}]")
          end
        end
      end


      it "maps {archival_object}.instance[].instance_type and {archival_object}.instance[].container.barcode_1 to {desc_path}/did/container@label" do
        instances.each do |inst|
          cont = inst['container']
          (1..3).each do |i|
            next unless cont.has_key?("type_#{i}") && cont.has_key?("indicator_#{i}")
            @count +=1
            next unless i == 1
            data = cont["indicator_#{i}"]
            mt(data, "#{desc_path}/did/container[#{@count}]")
            data = "#{translate('enumerations.instance_instance_type', inst['instance_type'])} (#{cont['barcode_1']})"
            mt(data, "#{desc_path}/did/container[#{@count}]", "label")
          end
        end
      end

      it "maps {archival_object}.instances[].container.barcode_1 to {desc_path}/did/container@label" do

      end
    end


    it "maps {archival_object}.extent to {desc_path}/did/physdesc" do
      count = 1
      object.extents.each do |ext|
        if ext['number'] && ext['extent_type']
          data = "#{ext['number']} #{translate('enumerations.extent_extent_type', ext['extent_type'])}"
          mt(data, "#{desc_path}/did/physdesc[#{count}]/extent[@altrender='materialtype spaceoccupied']")
        end
        if ext['container_summary']
          mt(ext['container_summary'], "#{desc_path}/did/physdesc[#{count}]/extent[@altrender='carrier']")
        end
        if ext['dimensions']
          mt(ext['dimensions'], "#{desc_path}/did/physdesc[#{count}]/dimensions")
        end
        if ext['physical_details']
          mt(ext['physical_details'], "#{desc_path}/did/physdesc[#{count}]/physfacet")
        end
        count += 1
      end
    end


    it "maps {archival_object}.date to {desc_path}/did/unitdate" do
      count = 1
      object.dates.each do |date|
        path = "#{desc_path}/did/unitdate[#{count}]"
        normal = "#{date['begin']}/"
        normal += (date['date_type'] == 'single' || date['end'].nil? || date['end'] == date['begin']) ? date['begin'] : date['end']
        type = %w(single inclusive).include?(date['date_type']) ? 'inclusive' : 'bulk'
        value = if date['expression']
                  date['expression']
                elsif date['date_type'] == 'bulk'
                  'bulk'
                elsif date['end'].nil? || date['end'] == date['begin']
                  date['begin']
                else
                  "#{date['begin']}-#{date['end']}"
                end

        mt(normal, path, 'normal')
        mt(type, path, 'type')
        mt(value, path)

        count += 1
      end
    end


    describe "How {archival_object}.notes data are mapped >> " do
      let(:notes) { object.notes }

      it "maps notes of type 'abstract' to did/abstract" do
        notes.select {|n| n['type'] == 'abstract'}.each_with_index do |note, i|
          path = "#{desc_path}/did/abstract[#{i+1}]"
          mt(note_content(note), path)
          if note['persistent_id']
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      it "maps notes of type 'dimensions' to did/physdesc/dimensions" do
        notes.select {|n| n['type'] == 'dimensions'}.each_with_index do |note, i|
          path = "#{desc_path}/did/physdesc[dimensions][#{i+1}]/dimensions"
          mt(note_content(note).gsub("<p>",'').gsub("</p>", ""), path, :markup)
          if note['persistent_id']
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      it "maps notes of type 'physdesc' to did/physdesc" do
        notes.select {|n| n['type'] == 'physdesc'}.each do |note|
          content = note_content(note)
          path = "#{desc_path}/did/physdesc[text()='#{content}']"
          if note['persistent_id']
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      it "maps notes of type 'langmaterial' to did/langmaterial" do
        notes.select {|n| n['type'] == 'langmaterial'}.each_with_index do |note, i|
          content = note_content(note)
          path = "#{desc_path}/did/langmaterial[text()='#{content}']"
          if note['persistent_id']
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      it "maps notes of type 'physloc' to did/physloc" do
        notes.select {|n| n['type'] == 'physloc'}.each_with_index do |note, i|
          path = "#{desc_path}/did/physloc[#{i+1}]"
          mt(note_content(note), path)
          if note['persistent_id']
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      it "maps notes of type 'materialspec' to did/materialspec" do
        notes.select {|n| n['type'] == 'materialspec'}.each_with_index do |note, i|
          path = "#{desc_path}/did/materialspec[#{i+1}]"
          mt(note_content(note), path)
          if !note['persistent_id'].nil?
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      it "maps notes of type 'physfacet' to did/physdesc/physfacet" do
        notes.select {|n| n['type'] == 'physfacet'}.each_with_index do |note, i|
          path = "#{desc_path}/did/physdesc[physfacet][#{i+1}]/physfacet"
          mt(note_content(note), path)
          if !note['persistent_id'].nil?
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end
    end


    describe "How the <controlled> access section gets built >> " do

      def node_name_for_term_type(type)
        case type
        when 'function'; 'function'
        when 'genre_form', 'style_period';  'genreform'
        when 'geographic', 'cultural_context'; 'geogname'
        when 'occupation';  'occupation'
        when 'topical'; 'subject'
        when 'uniform_title'; 'title'
        else; nil
        end
      end

      it "maps linked agents with role 'subject' or 'source' to {desc_path}/controlaccess/NODE" do
        object.linked_agents.each do |link|
          link_role = link[:role] || link['role']
          ref = link[:ref] || link['ref']
          agent = @agents[ref]
          node_name = case agent.agent_type
                      when 'agent_person'; 'persname'
                      when 'agent_family'; 'famname'
                      when 'agent_corporate_entity'; 'corpname'
                      end

          # https://archivesspace.atlassian.net/browse/AR-985?focusedCommentId=17531&page=com.atlassian.jira.plugin.system.issuetabpanels:comment-tabpanel#comment-17531
          if link_role == 'creator'
            path = "#{desc_path}/controlaccess/#{node_name}[contains(text(), '#{agent.names[0]['sort_name']}')]"
            doc.should_not have_node(path)
          end

          next unless %w(source subject).include?(link_role)
          relator = link[:relator] || link['relator']
          role = relator ? relator : (link_role == 'source' ? 'fmo' : nil)
          sort_name = agent.names[0]['sort_name']
          rules = agent.names[0]['rules']
          source = agent.names[0]['source']
          authfilenumber = agent.names[0]['authority_id']
          content = "#{sort_name}"

          terms = link[:terms] || link['terms']

          if terms.length > 0
            content << " -- "
            content << terms.map{|t| t['term']}.join(' -- ')
          end

          path = "#{desc_path}/controlaccess/#{node_name}[contains(text(), '#{sort_name}')]"

          mt(rules, path, 'rules')
          mt(source, path, 'source')
          mt(role, path, 'label')
          mt(authfilenumber, path, 'authfilenumber')
          mt(content.strip, path)
        end
      end


      it "maps linked subjects to {desc_path}/controlaccess/NODE" do
        object.subjects.each do |link|
          ref = link[:ref] || link['ref']
          subject = @subjects[ref]
          node_name = node_name_for_term_type(subject.terms[0]['term_type'])
          next unless node_name

          term_string = subject.terms.map{|t| t['term']}.join(' -- ')
          path = "/ead/archdesc/controlaccess/#{node_name}[text() = '#{term_string}']"

          mt(term_string, path)
          mt(subject.source, path, 'source')
          mt(subject.authority_id, path, 'authfilenumber')
        end
      end
    end
  end # end shared examples for resources & archival_objects


  describe "/eadheader mappings" do

    it "maps resource.finding_aid_status to @finding_aid_status" do
      {
        'findaidstatus' => @resource.finding_aid_status,
        'repositoryencoding' => "iso15511",
        'countryencoding' => "iso3166-1",
        'dateencoding' => "iso8601",
        'langencoding' => "iso639-2b"
      }.each do |tag, val|
        mt(val, "//eadheader", tag)
      end
    end

    it "maps repository.country to eadid/@countrycode" do
      mt(repo.country, "eadheader/eadid", "countrycode")
    end

    it "maps repository.country and repository.org_code to eadid/@mainagencycode" do
      data = (repo.country && repo.org_code) ? "#{repo.country}-#{repo.org_code}" : nil
      mt(data, "eadheader/eadid", 'mainagencycode')
    end

    it "maps resource.ead_location to eadid/@url" do
      mt(@resource.ead_location, "eadheader/eadid", 'url')
    end

    it "maps resource.ead_id to eadid" do
      mt(@resource.ead_id, "eadheader/eadid")
    end

    it "maps resource.finding_aid_title to filedesc/titlestmt/titleproper" do
      mt(@resource.finding_aid_title, "eadheader/filedesc/titlestmt/titleproper[not(@type)]")
    end

    it "maps resource.finding_aid_filing_title to filedesc/titlestmt/titleproper" do
      mt(@resource.finding_aid_filing_title, "eadheader/filedesc/titlestmt/titleproper[@type = 'filing']")
    end

    it "maps resource.(id_0|id_1|id_2|id_3) to filedesc/titlestmt/titleproper/num" do
      mt((0..3).map{|i| @resource.send("id_#{i}")}.compact.join('.'), "eadheader/filedesc/titlestmt/titleproper/num")
    end

    it "maps resource.finding_aid_author to filedesc/titlestmt/author" do
      data = @resource.finding_aid_author ? "Finding aid prepared by #{@resource.finding_aid_author}" : nil
      mt(data, "eadheader/filedesc/titlestmt/author")
    end

    it "maps resource.finding_aid_sponsor to filedesc/titlestmt/sponsor" do
      mt(@resource.finding_aid_sponsor, "eadheader/filedesc/titlestmt/sponsor")
    end

    it "maps resource.finding_aid_filing_title to filedesc/titlestmt/titleproper[@type == 'filing']" do
      mt(@resource.finding_aid_filing_title, "eadheader/filedesc/titlestmt/titleproper[@type='filing']")
    end

    it "maps resource.finding_aid_edition_statement to filedesc/editionstmt/p/finding_aid_edition_statement" do
      mt(@resource.finding_aid_edition_statement, "eadheader/filedesc/editionstmt/p/finding_aid_edition_statement")
    end

    it "maps repository.name to filedesc/publicationstmt/publisher" do
      mt(repo.name, "eadheader/filedesc/publicationstmt/publisher")
    end


    describe "repository.agent.agent_contacts[0] to filedesc/publicationstmt/address/ mappings" do
      let(:path) { "eadheader/filedesc/publicationstmt/address/" }
      let(:contact) { JSONModel(:agent_corporate_entity).find(1).agent_contacts[0] }
      let(:offset_1) { (1..3).map{|i| contact["address_#{i}"]}.compact.count + 1 }
      let(:offset_2) { %w(city region post_code).map{|k| contact[k]}.compact.length > 0 ? 1 : 0 }

      it "maps address_(1|2|3) to addressline" do
        j = 1
        (1..3).each do |i|
          al = contact["address_#{i}"]
          next unless al
          mt(al, "#{path}addressline[#{j}]")
          j+=1
        end
      end

      it "maps city, region, post_code to addressline" do
        line = %w(city region).map{|k| contact[k] }.compact.join(', ')
        line += " #{contact['post_code']}"
        line.strip!

        unless line.empty?
          mt(line, "#{path}addressline[#{offset_1}]")
        end
      end

      it "maps 'telephone' to addressline" do
        if (data = contact['telephone'])
          mt(data, "#{path}addressline[#{offset_1 + offset_2}]")
        end
      end

      it "maps 'email' to addressline" do
        offset_3 = contact['telephone'] ? 1 : 0
        if (data = contact['email'])
          mt(data, "#{path}addressline[#{offset_1 + offset_2 +  offset_3}]")
        end
      end
    end

    it "maps repository.image_url to filedesc/publicationstmt/p/extref@xlink:href" do
      if repo.image_url
        {
          repo.image_url => "xlink:href",
          "onLoad" => "xlink:actuate",
          "embed" => "xlink:show",
          "simple" => "xlink:type"
        }.each do |data, att|
          mt(data, "//xmlns:eadheader/xmlns:filedesc/xmlns:publicationstmt/xmlns:p/xmlns:extref", att)
        end
      else
        mt(nil, "eadheader/filedesc/publicationstmt/p/extref")
      end
    end

    it "maps resource.finding_aid_date to filedesc/publicationstmt/p/date" do
      mt(@resource.finding_aid_date, "eadheader/filedesc/publicationstmt/p/date")
    end

    it "maps resource.finding_aid_series_statement to filedesc/seriesstmt" do
      mt(@resource.finding_aid_series_statement, "eadheader/filedesc/seriesstmt")
    end

    it "maps resource.finding_aid_note to filedesc/notestmt/note/p" do
      mt(@resource.finding_aid_note, "eadheader/filedesc/notestmt/note/p")
    end

    it "produces a creation statement and timestamp at profiledesc/creation" do
      date_regex = '\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s?[-+]?\d*'
      full_regex = 'This finding aid was produced using ArchivesSpace on '+date_regex+'\.'
      mt(Regexp.new(full_regex), "//profiledesc/creation")
      mt(Regexp.new(date_regex), "//profiledesc/creation/date")
    end

    it "maps resource.finding_aid_language to profiledesc/langusage" do
      mt(@resource.finding_aid_language, "eadheader/profiledesc/langusage")
    end

    it "maps resource.finding_aid_description_rules to profiledesc/descrules" do
      data = @resource.finding_aid_description_rules ? translate('enumerations.resource_finding_aid_description_rules', @resource.finding_aid_description_rules) : nil
      mt(data, "//profiledesc/descrules")
    end

    it "maps resource.revision_statements.date to revisiondesc/change/date" do
      mt(@resource.revision_statements[0]["date"], "//revisiondesc/change/date")
    end

    it "maps resource.finding_aid_revision_description to revisiondesc/change/item" do
      mt(@resource.revision_statements[0]["description"], "//revisiondesc/change/item")
    end
  end


  describe "How the /ead/archdesc section gets built >> " do

    it_behaves_like "archival object desc mappings" do
      let(:object) { @resource }
      let(:desc_path) { "/ead/archdesc" }
      let(:desc_nspath) { "/xmlns:ead/xmlns:archdesc" }
      let(:unitid_src) { (0..3).map{|i| object.send("id_#{i}")}.compact.join('.') }
    end


    it "maps repository.name to archdesc/repository/corpname" do
      mt(repo.name, "archdesc/did/repository/corpname")
    end
  end


  describe "How linked agents are mapped to the ead/archdesc/did section >> " do

    it "maps linked agents with role of 'source' or 'creator' to archdesc/did/origination/(pers|fam|corp)name" do
      @resource.linked_agents.each do |link|
        role = link[:role]
        next unless %w(source creator).include?(role)
        relator = link[:relator]
        agent = @agents[link[:ref]]
        sort_name = agent.names[0]['sort_name']
        rules = agent.names[0]['rules']
        source = agent.names[0]['source']
        node_name = case agent.agent_type
                    when 'agent_person'; 'persname'
                    when 'agent_family'; 'famname'
                    when 'agent_corporate_entity'; 'corpname'
                    end

        path_1 = "archdesc/did/origination[#{node_name}[contains(text(), '#{sort_name}')]]"
        path_2 = "archdesc/did/origination/#{node_name}[text()='#{sort_name}']"

        mt(role, path_1, 'label')
        mt(rules, path_2, 'rules')
        mt(source, path_2, 'source')
        mt(sort_name, path_2)
      end
    end
  end


  describe "How digital_objects are mapped to <dao> nodes >> " do
    let(:digital_objects) { @digital_objects.values }

    def description_content(obj)

      date = obj.dates[0] || {}
      content = ""
      content << "#{obj.title}" if obj.title
      content << ": " if date['expression'] || date['begin']
      if date['expression']
        content << date['expression']
      elsif date['begin']
        content << date['begin']
        if date['end'] != date['begin']
          content << "-#{date['end']}"
        end
      end

      content
    end

    it "maps each resource.instances[].instance.digital_object to archdesc/dao" do
      digital_objects.each do |obj|
        if obj['file_versions'].length > 0
          obj['file_versions'].each do |fv|
            href = fv["file_uri"] || obj.digital_object_id
            path = "/xmlns:ead/xmlns:archdesc/xmlns:dao[@xlink:href='#{href}']"
            content = description_content(obj)
            xlink_actuate_attribute = fv['xlink_actuate_attribute'] || 'onRequest'
            mt(xlink_actuate_attribute, path, 'xlink:actuate')
            xlink_show_attribute = fv['xlink_show_attribute'] || 'new'
            mt(xlink_show_attribute, path, 'xlink:show')
            mt(obj.title, path, 'xlink:title')
            mt(content, "#{path}/xmlns:daodesc/xmlns:p")
          end
        else
          href =  obj.digital_object_id
          path = "/xmlns:ead/xmlns:archdesc/xmlns:dao[@xlink:href='#{href}']"
          content = description_content(obj)
          xlink_actuate_attribute =  'onRequest'
          mt(xlink_actuate_attribute, path, 'xlink:actuate')
          xlink_show_attribute =  'new'
          mt(xlink_show_attribute, path, 'xlink:show')
          mt(obj.title, path, 'xlink:title')
          mt(content, "#{path}/xmlns:daodesc/xmlns:p")
        end
      end
    end

  end


  describe "How the <dsc> section is built >> " do

    (0...10).each do |i|
      let(:archival_object) { @archival_objects.values[i] || @archival_objects.values.sample }
      let(:ref_id) { "#{I18n.t('archival_object.ref_id_export_prefix', :default => 'aspace_')}#{archival_object.ref_id}" }
      let(:path) { "//c[@id='#{ref_id}']" }
      let(:nspath) { "//xmlns:c[@id='#{ref_id}']"}

      it "maps archival_object.ref_id to //c[@id]" do
        doc.should have_node(path)
      end

      it_behaves_like "archival object desc mappings" do
        let(:object) { archival_object }
        let(:desc_path) { path }
        let(:desc_nspath) { nspath }
        let(:unitid_src) { object.component_id }
      end

      describe "How {archival_object}.instances[].digital_object data is mapped." do
        let(:instances) { archival_object.instances.reject {|i| i['digital_object'].nil? } }

        def description_content(obj)
          date = obj['dates'].nil? ? {} : obj['dates'][0]
          content = ""
          content << "#{obj['title']}" if obj['title']
          unless date.nil?
            content << ": " if date['expression'] || date['begin']
            if date['expression']
              content << "#{date['expression']}"
            elsif date['begin']
              content << "#{date['begin']}"
              if date['end'] != date['begin']
                content << "-#{date['end']}"
              end
            end
          end
          content
        end
      end
    end
  end

  describe "Testing EAD Serializer mixed content behavior" do

    let(:note_with_p) { "<p>A NOTE!</p>" }
    let(:note_with_linebreaks) { "Something, something,\n\nsomething." }
    let(:note_with_linebreaks_and_good_mixed_content) { "Something, something,\n\n<bioghist>something.</bioghist>\n\n" }
    let(:note_with_linebreaks_and_evil_mixed_content) { "Something, something,\n\n<bioghist>something.\n\n</bioghist>\n\n" }
    let(:serializer) { EADSerializer.new }

    it "can strip <p> tags from content when disallowed" do
      serializer.strip_p(note_with_p).should eq("A NOTE!")
    end

    it "can leave <p> tags in content" do
      serializer.handle_linebreaks(note_with_p).should eq(note_with_p)
    end

    it "will add <p> tags to content with linebreaks" do
      serializer.handle_linebreaks(note_with_linebreaks).should eq("<p>Something, something,</p><p>something.</p>")
    end

    it "will add <p> tags to content with linebreaks and mixed content" do
      serializer.handle_linebreaks(note_with_linebreaks_and_good_mixed_content).should eq("<p>Something, something,</p><p><bioghist>something.</bioghist></p>")
    end

    it "will return original content when linebreaks and mixed content produce invalid markup" do
      serializer.handle_linebreaks(note_with_linebreaks_and_evil_mixed_content).should eq(note_with_linebreaks_and_evil_mixed_content)
    end

  end
end
