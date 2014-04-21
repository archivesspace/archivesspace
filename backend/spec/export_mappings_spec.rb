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


  #######################################################################


  describe "EAD export mappings" do

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
          @doc = get_xml_doc("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_unpublished=true&include_daos=true")
          @doc_nsless = Nokogiri::XML::Document.parse(@doc.to_xml)
          @doc_nsless.remove_namespaces!

          raise Sequel::Rollback
        end
      end
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
        mt(object.title, "#{desc_path}/did/unittitle")
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
          %w(accruals appraisal arrangement bioghist accessrestirct userestrict custodhist altformavail originalsloc fileplan odd acqinfo otherfindaid phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial)
        }

        it "maps note content to {desc_path}/NOTE_TAG" do
          object.notes.select{|n| archdesc_note_types.include?(n['type'])}.each do |note|

            head_text = note['label'] ? note['label'] : translate('enumerations._note_types', note['type'])
            id = note['persistent_id']
            content = note_content(note)
            path = "#{desc_path}/#{note['type']}"
            path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"

            mt(id, path, 'id')
            mt(head_text, "#{path}/head")
            mt(content, "#{path}/p")
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
            id = note['persistent_id']
            content = note_content(note)
            path = "#{desc_path}/bibliography"
            path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"

            mt(id, path, 'id')
            mt(head_text, "#{path}/head")
            mt(content, "#{path}/p")

            note['items'].each_with_index do |item, i|
              mt(item, "#{path}/bibref[#{i+1}]")
            end
          end
        end


        it "maps notes[].note_index to {desc_path}/index" do
          indexes.each do |note|
            head_text = note['label']
            id = note['persistent_id']
            content = note_content(note)
            path = "#{desc_path}/index"
            path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"

            mt(id, path, 'id')
            mt(head_text, "#{path}/head")
            mt(content, "#{path}/p")

            note['items'].each_with_index do |item, i|
              index_item_type_map.keys.should include(item['type'])
              item_path = "#{path}/indexentry[#{i+1}]"
              mt(item['value'], "#{item_path}/#{index_item_type_map[item['type']]}")
              mt(item['reference'], "#{item_path}/ref", 'target')
              mt(item['reference_text'], "#{item_path}/ref")
            end
          end
        end
      end


      describe "How mixed content notes are mapped >> " do
        let(:archdesc_note_types) {
          %w(accruals appraisal arrangement bioghist accessrestirct userestrict custodhist altformavail originalsloc fileplan odd acqinfo otherfindaid phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial)
        }
        let(:multis) { object.notes.select{|n| n['subnotes'] && (archdesc_note_types).include?(n['type']) } }

        let(:build_path) { Proc.new {|note|
            content = note_content(note)
            id = note['persistent_id']
            path = "#{desc_path}/#{note['type']}"
            path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"
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
                  mt(event, event_path)
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
                mt(item['value'], "#{dl_path}/defitem[#{j+1}]/item")
              end
            end
          end
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


        it "maps {archival_object}.instance[].instance_type to {desc_path}/did/container@label" do
          instances.each do |inst|
            cont = inst['container']
            (1..3).each do |i|
              next unless cont.has_key?("type_#{i}") && cont.has_key?("indicator_#{i}")
              @count +=1
              next unless i == 1
              data = cont["indicator_#{i}"]
              mt(data, "#{desc_path}/did/container[#{@count}]")
              data = translate('enumerations.instance_instance_type', inst['instance_type'])
              mt(data, "#{desc_path}/did/container[#{@count}]", "label")
            end
          end
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
            mt(note['persistent_id'], path, "id")
          end
        end


        it "maps notes of type 'dimensions' to did/physdesc/dimensions" do
          notes.select {|n| n['type'] == 'dimensions'}.each_with_index do |note, i|
            path = "#{desc_path}/did/physdesc[dimensions][#{i+1}]/dimensions"
            mt(note_content(note), path)
            mt(note['persistent_id'], path, "id")
          end
        end


        it "maps notes of type 'physdesc' to did/physdesc" do
          notes.select {|n| n['type'] == 'physdesc'}.each do |note|
            content = note_content(note)
            path = "#{desc_path}/did/physdesc[text()='#{content}']"
            mt(note['persistent_id'], path, "id")
          end
        end


        it "maps notes of type 'langmaterial' to did/langmaterial" do
          notes.select {|n| n['type'] == 'langmaterial'}.each_with_index do |note, i|
            content = note_content(note)
            path = "#{desc_path}/did/langmaterial[text()='#{content}']"
            mt(note['persistent_id'], path, "id")
          end
        end


        it "maps notes of type 'physloc' to did/physloc" do
          notes.select {|n| n['type'] == 'physloc'}.each_with_index do |note, i|
            path = "#{desc_path}/did/physloc[#{i+1}]"
            mt(note_content(note), path)
            mt(note['persistent_id'], path, "id")
          end
        end


        it "maps notes of type 'materialspec' to did/materialspec" do
          notes.select {|n| n['type'] == 'materialspec'}.each_with_index do |note, i|
            path = "#{desc_path}/did/materialspec[#{i+1}]"
            mt(note_content(note), path)
            mt(note['persistent_id'], path, "id")
          end
        end


        it "maps notes of type 'physfacet' to did/physdesc/physfacet" do
          notes.select {|n| n['type'] == 'physfacet'}.each_with_index do |note, i|
            path = "#{desc_path}/did/physdesc[physfacet][#{i+1}]/physfacet"
            mt(note_content(note), path)
            mt(note['persistent_id'], path, "id")
          end
        end
      end


      describe "How the <controlled> access section gets built >> " do

        def node_name_for_term_type(type)
          case type
          when 'function'; 'function'
          when 'genre_form' || 'style_period';  'genreform'
          when 'geographic'|| 'cultural_context'; 'geogname'
          when 'occupation';  'occupation'
          when 'topical'; 'subject'
          when 'uniform_title'; 'title'
          else; nil
          end
        end

        it "maps linked agents with role 'subject' or 'source' to {desc_path}/controlaccess/NODE" do
          object.linked_agents.each do |link|
            link_role = link[:role] || link['role']
            next unless %w(source subject).include?(link_role)
            relator = link[:relator] || link['relator']
            ref = link[:ref] || link['ref']
            role = relator ? relator : (link_role == 'source' ? 'fmo' : nil)
            agent = @agents[ref]
            sort_name = agent.names[0]['sort_name']
            rules = agent.names[0]['rules']
            source = agent.names[0]['source']
            content = "#{sort_name}"

            terms = link[:terms] || link['terms']

            if terms.length > 0
              content << " -- "
              content << terms.map{|t| t['term']}.join(' -- ')
            end

            node_name = case agent.agent_type
                        when 'agent_person'; 'persname'
                        when 'agent_family'; 'famname'
                        when 'agent_corporate_entity'; 'corpname'
                        end

            path = "#{desc_path}/controlaccess/#{node_name}[contains(text(), '#{sort_name}')]"

            mt(rules, path, 'rules')
            mt(source, path, 'source')
            mt(role, path, 'label')
            mt(content, path)
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
        mt(@resource.finding_aid_title, "eadheader/filedesc/titlestmt/titleproper[@type != 'filing']")
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
            "simple" => "xlink:linktype"
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

      it "maps resource.finding_aid_revision_date to revisiondesc/change/date" do
        mt(@resource.finding_aid_revision_date, "//revisiondesc/change/date")
      end

      it "maps resource.finding_aid_revision_description to revisiondesc/change/item" do
        mt(@resource.finding_aid_revision_description, "//revisiondesc/change/item")
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
          fv = obj['file_versions'][0] || {}
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
