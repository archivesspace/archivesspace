# encoding: utf-8
require 'nokogiri'
require 'spec_helper'
require_relative 'export_spec_helper'

# Used to check that the fields EAD needs resolved are being resolved by the indexer.
require_relative '../../indexer/app/lib/indexer_common_config'

describe "EAD export mappings" do

  #######################################################################
  # FIXTURES
  #######################################################################

  def load_export_fixtures
    @agents = {}
    5.times {
      a = create([:json_agent_person, :json_agent_corporate_entity, :json_agent_family].sample, :publish => true)
      @agents[a.uri] = a
    }

    @subjects = {}
    5.times {
      s = create(:json_subject)
      @subjects[s.uri] = s
    }

    @digital_objects = {}
    3.times {
      d = create(:json_digital_object, :publish => true)
      @digital_objects[d.uri] = d
    }
    # ANW-285: Add some file_versions with publish = false to test that exporter handles them correctly
    2.times {
      d = create(:json_digital_object_unpub_files, :publish => true)
      @digital_objects[d.uri] = d
    }

    instances = []
    @digital_objects.keys.each do |ref|
      instances << build(:json_instance_digital,
                         :instance_type => 'digital_object',
                         :digital_object => {:ref => ref})
    end

    @top_container = create(:json_top_container)
    3.times {
      instances << build(:json_instance,
                         :sub_container => build(:json_sub_container,
                                                 :top_container => {:ref => @top_container.uri}))
    }

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
                                                   build(:json_note_definedlist, { :publish => true, :title => "note_definedlist",
                                                           :items => [
                                                                      {:label => "First Mate", :value => "<persname encodinganalog='600$a' source='lcnaf'>Gilligan</persname>" },
                                                                      {:label => "Captain", :value => "The Skipper"},
                                                                      {:label => "Etc.", :value => "The Professor and Mary Ann" }
                                                                     ]
                                                         }),
                                                   build(:json_note_text, { :content => "note_text - Here on Gillgian's Island", :publish => true}) ,
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


    resource = create(:json_resource,
                      :linked_agents => build_linked_agents(@agents),
                      :notes => build_archival_object_notes(30) + [@mixed_subnotes_tracer, @another_note_tracer],
                      :subjects => @subjects.map {|ref, s| {:ref => ref}},
                      :instances => instances,
                      :finding_aid_status => %w(completed in_progress under_revision unprocessed).sample,
                      :finding_aid_filing_title => "this is a filing title",
                      :finding_aid_series_statement => "here is the series statement",
                      :publish => true,
                      :metadata_rights_declarations => [build(:json_metadata_rights_declaration)]
                      )


    @resource = JSONModel(:resource).find(resource.id, 'resolve[]' => 'top_container')

    @archival_objects = {}

    10.times {
      parent = [true, false].sample ? @archival_objects.keys[rand(@archival_objects.keys.length)] : nil
      a = create(:json_archival_object, :resource => {:ref => @resource.uri},
                 :parent => parent ? {:ref => parent} : nil,
                 :notes => build_archival_object_notes(5),
                 :linked_agents => build_linked_agents(@agents),
                 :lang_materials => [build(:json_lang_material),
                                     build(:json_lang_material)],
                 :instances => [build(:json_instance_digital),
                                build(:json_instance,
                                      :sub_container => build(:json_sub_container,
                                                              :top_container => {:ref => @top_container.uri}))
                               ],
                 :subjects => @subjects.map {|ref, s| {:ref => ref}}.shuffle,
                 :publish => true,
                 )

      a = JSONModel(:archival_object).find(a.id, 'resolve[]' => 'top_container')

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

    if data
      expect(doc).to have_node(path)
      if trib.nil?
        expect(node).to have_inner_text(data)
      elsif trib == :markup
        expect(node).to have_inner_markup(data)
      else
        expect(node).to have_attribute(trib, data)
      end
    elsif node && trib
      expect(node).not_to have_attribute(trib)
    end
  end

  def build_multipart_notes(max = 5)
    note_types = %w(odd dimensions phystech processinfo separatedmaterial arrangement fileplan accessrestrict scopecontent prefercite acqinfo altformavail originalsloc userestrict legalstatus relatedmaterial custodhist appraisal accruals bioghist)
    notes = []
    brake = 0
    while !(note_types - notes.map {|note| note['type']}).empty? && brake < max do
      notes << build("json_note_#{['multipart', 'multipart_gone_wilde'].sample}".intern, {
                       :publish => true,
                       :label => generate(:alphanumstr),
                       :persistent_id => [nil, generate(:alphanumstr)].sample
                     })
      brake += 1
    end

    notes
  end

  def build_singlepart_notes(max = 5)
    note_types = %w(physdesc materialspec physloc physfacet abstract)
    notes = []
    brake = 0
    while !(note_types - notes.map {|note| note['type']}).empty? && brake < max do
      notes << build(:json_note_singlepart, {
                       :publish => true,
                       :label => generate(:alphanumstr),
                       :persistent_id => [nil, generate(:alphanumstr)].sample
                     })
      brake += 1
    end

    notes
  end

  def build_archival_object_notes(max = 2)
    note_types = %w(bibliography index)
    notes = []
    note_types.each do |note_type|
      notes << build("json_note_#{note_type}".intern, {
                       :publish => true,
                       :label => generate(:alphanumstr),
                       :persistent_id => [nil, generate(:alphanumstr)].sample
                     })
    end

    notes = notes + build_singlepart_notes(max) + build_multipart_notes(max)
    notes
  end


  def build_linked_agents(agents)
    agents = agents.map {|ref, a| {
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
    as_test_user('admin') do
      RSpec::Mocks.with_temporary_scope do
        # EAD export normally tries the search index first, but for the tests we'll
        # skip that since Solr isn't running.
        allow(Search).to receive(:records_for_uris) do |*|
          {'results' => []}
        end

        as_test_user("admin", true) do
          load_export_fixtures
          @doc = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_unpublished=true&include_daos=true&include_uris=true")
          @doc_unpub = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_daos=true&include_uris=true")
          @doc_nsless = Nokogiri::XML::Document.parse(@doc.to_xml)
          @doc_nsless.remove_namespaces!

          @doc_include_uris_false = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_daos=true&include_uris=false")
          @doc_include_uris_missing = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_daos=true")
          @doc_include_uris_false.remove_namespaces!
          @doc_include_uris_missing.remove_namespaces!

          raise Sequel::Rollback
        end
      end
      expect(@doc.errors.length).to eq(0)

      # if the word Nokogiri appears in the XML file, we'll assume something
      # has gone wrong
      expect(@doc.to_xml).not_to include("Nokogiri")
      expect(@doc.to_xml).not_to include("#&amp;")
    end
  end

  let(:repo) { JSONModel(:repository).find($repo_id) }

  describe "indexing prerequisites" do
    it "resolves all required fields for the EAD model" do
      missing_fields = (EADModel::RESOLVE - IndexerCommonConfig.resolved_attributes)

      expect(missing_fields).to eq([])
    end
  end

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

    it "maps {archival_object}.uri to {desc_path}/did/unitid[@type='aspace_uri']" do
      mt(object.uri, "#{desc_path}/did/unitid[@type='aspace_uri']")
    end

    it "does not map {archival_object}.uri to {desc_path}/did/unitid[@type='aspace_uri'] if include_uris is false" do
      expect(@doc_include_uris_false).not_to have_node(desc_path + "/did/unitid[@type='aspace_uri']")
    end

    it "does map {archival_object}.uri to {desc_path}/did/unitid[@type='aspace_uri'] if include_uris is missing" do
      expect(@doc_include_uris_missing).to have_node(desc_path + "/did/unitid[@type='aspace_uri']")
    end

    it "maps {archival_object}.lang_materials['language_and_script'] to {desc_path}/did/langmaterial/language" do

      language = object.lang_materials[0]['language_and_script']['language']
      script = object.lang_materials[0]['language_and_script']['script']

      mt(translate('enumerations.language_iso639_2', language), "#{desc_path}/did/langmaterial/language")
      mt(language, "#{desc_path}/did/langmaterial/language", 'langcode')
      mt(script, "#{desc_path}/did/langmaterial/language", 'scriptcode')
    end


    it "maps {archival_object}.lang_materials['notes'] to {desc_path}/did/langmaterial if present" do

      language_notes = object.lang_materials << build(:json_lang_material_with_note)

      language_notes.select {|n| n['type'] == 'langmaterial'}.each_with_index do |note, i|
        content = note_content(note)
        path = "#{desc_path}/did/langmaterial[text()='#{content}']"
        if note['persistent_id']
          mt("aspace_" + note['persistent_id'], path, "id")
        else
          mt(nil, path, "id")
        end
      end

      language_notes.pop

    end


    describe "archdesc or component notes section: " do
      let(:archdesc_note_types) {
        %w(accruals appraisal arrangement bioghist accessrestrict userestrict custodhist altformavail originalsloc fileplan odd acqinfo otherfindaid phystech prefercite processinfo relatedmaterial scopecontent separatedmaterial)
      }

      it "maps note content to {desc_path}/NOTE_TAG" do
        object.notes.select {|n| archdesc_note_types.include?(n['type'])}.each do |note|
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
      let(:index_item_type_map) { {
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
            expect(index_item_type_map.keys).to include(item['type'])
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
      let(:multis) { object.notes.select {|n| n['subnotes'] && (archdesc_note_types).include?(n['type']) } }

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
              mt(item['value'], "#{dl_path}/defitem[#{j+1}]/item", :markup)
            end
          end
        end
      end

      it "ensures subnotes[] order is respected, even if subnotes are of mixed types" do

        path = "//bioghist[@id = 'aspace_#{@mixed_subnotes_tracer['persistent_id']}']"
        head_text = translate('enumerations._note_types', @mixed_subnotes_tracer['type'])

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

    describe "How {archival_object}.instances[].sub_container data is mapped." do
      let(:instances) { object.instances.reject {|i| i['sub_container'].nil? } }

      it "maps {archival_object}.instances[].sub_container to {desc_path}/did/container" do
        container_ix = 1

        instances.each do |inst|
          # increment 1 for the top_container
          container_ix += 1

          sub = inst['sub_container']
          if sub['type_2']
            mt(sub['type_2'], "#{desc_path}/did/container[#{container_ix}]", "type")
            mt(sub['indicator_2'], "#{desc_path}/did/container[#{container_ix}]")
            container_ix += 1
          end

          if sub['type_3']
            mt(sub['type_3'], "#{desc_path}/did/container[#{container_ix}]", "type")
            mt(sub['indicator_3'], "#{desc_path}/did/container[#{container_ix}]")
            container_ix += 1
          end
        end
      end


      it "maps {archival_object}.instance[].instance_type and {archival_object}.instance[].sub_container.top_container.barcode to {desc_path}/did/container@label" do
        container_ix = 1

        instances.each do |inst|
          sub = inst['sub_container']
          top = sub['top_container']['_resolved']

          mt(top['indicator'], "#{desc_path}/did/container[#{container_ix}]")

          label = translate('enumerations.instance_instance_type', inst['instance_type'])
          label += " [#{top['barcode']}]" if top['barcode']
          mt(label, "#{desc_path}/did/container[#{container_ix}]", "label")

          container_ix += 1

          # skip the children
          container_ix += 1 if sub['type_2']
          container_ix += 1 if sub['type_3']
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
        type = ( date['date_type'] == 'inclusive' ) ? 'inclusive' :  ( ( date['date_type'] == 'single') ? nil : 'bulk')
        # type = %w(single inclusive).include?(date['date_type']) ? 'inclusive' : 'bulk'
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

          mt(note['label'], path, "label")
        end
      end


      it "maps notes of type 'dimensions' to did/physdesc/dimensions" do
        notes.select {|n| n['type'] == 'dimensions'}.each_with_index do |note, i|
          id = "aspace_" + note['persistent_id']
          content = note_content(note).gsub("<p>", '').gsub("</p>", "")
          path = "did/physdesc[not(@altrender)][dimensions][#{i+1}]/dimensions"
          path += id ? "[@id='#{id}']" : "[p[contains(text(), #{content})]]"
          full_path = "#{desc_path}/#{path}"
          mt(content, full_path, :markup)
          mt(note['label'], full_path, "label") if note['label']
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

          mt(note['label'], path, "label")
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
          id = "aspace_" + note['persistent_id']
          content = note_content(note)
          path = "did/physdesc[not(@altrender)][physfacet][#{i+1}]/physfacet"
          path += id ? "[@id='#{id}']" : "[p[contains(text(), #{content})]]"
          full_path = "#{desc_path}/#{path}"
          mt(content, full_path)

          mt(note['label'], full_path, "label")
        end
      end

    end


    describe "How the <controlled> access section gets built >> " do

      def node_name_for_term_type(type)
        case type
        when 'function'; 'function'
        when 'genre_form', 'style_period'; 'genreform'
        when 'geographic', 'cultural_context'; 'geogname'
        when 'occupation'; 'occupation'
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
            expect(doc).not_to have_node(path)
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
            content << terms.map {|t| t['term']}.join(' -- ')
          end

          path = "#{desc_path}/controlaccess/#{node_name}[contains(text(), '#{sort_name}')]"

          mt(rules, path, 'rules')
          mt(source, path, 'source')
          mt(role, path, 'label')
          mt(authfilenumber, path, 'authfilenumber')
          mt(content.strip, path)
        end
      end


      # AR-1459
      it "maps linked agents with role 'creator' to {desc_path}/did/origination/NODE" do
        object.linked_agents.each do |link|
          link_role = link[:role] || link['role']
          next unless link_role == 'creator'

          ref = link[:ref] || link['ref']
          agent = @agents[ref]
          node_name = case agent.agent_type
                      when 'agent_person'; 'persname'
                      when 'agent_family'; 'famname'
                      when 'agent_corporate_entity'; 'corpname'
                      end

          path = "#{desc_path}/did/origination/#{node_name}[contains(text(), '#{agent.names[0]['sort_name']}')]"
          expect(doc).to have_node(path)
        end
      end


      it "maps linked subjects to {desc_path}/controlaccess/NODE" do
        object.subjects.each do |link|
          ref = link[:ref] || link['ref']
          subject = @subjects[ref]
          node_name = node_name_for_term_type(subject.terms[0]['term_type'])
          next unless node_name

          term_string = subject.terms.map {|t| t['term']}.join(' -- ')
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
      mt((0..3).map {|i| @resource.send("id_#{i}")}.compact.join('.'), "eadheader/filedesc/titlestmt/titleproper/num")
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
      let(:offset_1) { (1..3).map {|i| contact["address_#{i}"]}.compact.count + 1 }
      let(:offset_2) { %w(city region post_code).map {|k| contact[k]}.compact.length > 0 ? 1 : 0 }

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
        line = %w(city region).map {|k| contact[k] }.compact.join(', ')
        line += " #{contact['post_code']}"
        line.strip!

        unless line.empty?
          mt(line, "#{path}addressline[#{offset_1}]")
        end
      end

      it "maps each telephone in 'telephones' to addressline" do
        if (data = contact['telephones'][0])
          mt(/#{data['number']}/, "#{path}addressline[#{offset_1 + offset_2}]")
          if data['number_type']
            mt(/#{data['number_type'].capitalize}/, "#{path}addressline[#{offset_1 + offset_2}]")
          end
          if data['ext']
            mt(/#{data['ext']}/, "#{path}addressline[#{offset_1 + offset_2}]")
          end
        end
      end

      it "maps 'email' to addressline" do
        offset_3 = contact['telephones'] ? 1 : 0
        if (data = contact['email'])
          mt(data, "#{path}addressline[#{offset_1 + offset_2 + offset_3}]")
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

    it "maps resource.finding_aid_language_note to profiledesc/langusage" do
      mt(@resource.finding_aid_language_note, "eadheader/profiledesc/langusage")
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


  # describe "How the /ead/archdesc section gets built >> " do
  #
  #   it_behaves_like "archival object desc mappings" do
  #     let(:object) { @resource }
  #     let(:desc_path) { "/ead/archdesc" }
  #     let(:desc_nspath) { "/xmlns:ead/xmlns:archdesc" }
  #     let(:unitid_src) { (0..3).map{|i| object.send("id_#{i}")}.compact.join('.') }
  #   end
  #
  #
  #   it "maps repository.name to archdesc/repository/corpname" do
  #     mt(repo.name, "archdesc/did/repository/corpname")
  #   end
  # end


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

    # ANW-777
    it "capitalizes instances of agent role 'creator' that are mapped to origination/@label" do
      origination_labels = doc.xpath("//origination/@label")

      origination_labels.each do |origination_label|
        next unless origination_label.content == 'creator'
        expected_label = origination_label.content.capitalize
        expect(origination_label.content).to eq(expected_label)
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

    # TODO: Fix this test
    xit "maps each resource.instances[].instance.digital_object to archdesc/dao" do
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
          href = obj.digital_object_id
          path = "/xmlns:ead/xmlns:archdesc/xmlns:dao[@xlink:href='#{href}']"
          content = description_content(obj)
          xlink_actuate_attribute = 'onRequest'
          mt(xlink_actuate_attribute, path, 'xlink:actuate')
          xlink_show_attribute = 'new'
          mt(xlink_show_attribute, path, 'xlink:show')
          mt(obj.title, path, 'xlink:title')
          mt(content, "#{path}/xmlns:daodesc/xmlns:p")
        end
      end
    end

    # ANW-285: This test set is generating random data for digital objects in the EAD export.
    # The XML generated is different every time the test is run, hence this test is cycling through
    # all the digital objects defined in the current run rather that use a deterministic approach.
    it "displays file_uri if file version is published, digital_object_id otherwise" do

      # for each digital object generated
      digital_objects.each do |d|
        digital_object_id = d['digital_object_id']
        visible_file_versions = d['file_versions'].select {|fv| fv['publish'] == true }

        if visible_file_versions.length == 0
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:dao"
        elsif visible_file_versions.length == 1
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:dao"
        elsif visible_file_versions.length > 1
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:daogrp/xmlns:daoloc"
        end


        # for each file version in the digital object
        d['file_versions'].each do |fv|
          file_uri = fv['file_uri']
          next unless file_uri

          publish = fv['publish']

          if publish
            expect(@doc_unpub).to have_node(basepath + "[@xlink:href='#{file_uri}']")
          else
            expect(@doc_unpub).not_to have_node(basepath + "[@xlink:href='#{file_uri}']")
          end
        end
      end
    end

    it "always displays file_uri in dao tags if EAD generated with include_unpublished = true" do
      # for each digital object generated
      digital_objects.each do |d|

        file_versions = d['file_versions']

        if file_versions.length == 0
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:dao"
        elsif file_versions.length == 1
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:dao"
        elsif file_versions.length > 1
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:daogrp/xmlns:daoloc"
        end

        # for each file version in the digital object
        file_versions.each do |fv|
          file_uri = fv['file_uri']
          next unless file_uri

          publish = fv['publish']

          if publish
            expect(@doc).to have_node(basepath + "[@xlink:href='#{file_uri}']")
          else
            expect(@doc).to have_node(basepath + "[@xlink:href='#{file_uri}']")
          end
        end
      end
    end

    # ANW-805: Moved audience attribute of dao/daoloc to its own test. Still quite rudimentary.
    it "sets audience attribute in dao tags according to publish status of both digital object and file version" do
      # for each digital object generated
      digital_objects.each do |d|

        file_versions = d['file_versions']

        if file_versions.length < 2
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:dao"
        else
          basepath = "/xmlns:ead/xmlns:archdesc/xmlns:daogrp/xmlns:daoloc"
        end

        # for each file version in the digital object
        file_versions.each do |fv|

          publish = fv['publish'] && d['publish']

          if publish
            expect(@doc).to have_node(basepath + "[not(@audience='internal')]")
          else
            expect(@doc).to have_node(basepath + "[@audience='internal']")
          end
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
        expect(doc).to have_node(path)
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
    let(:note_with_archref) {"<archref audience='external'/>"}
    let(:note_with_bibref) {"<bibref audience='internal'/>"}
    let(:note_with_extptr) {"<extptr linktype='simple' entityref='entref' title='title' show='embed'/>"}
    let(:note_with_extptrloc) {"<extptrloc href='http://www.example.com'/>"}
    let(:note_with_extrefloc) {"<extrefloc href='http://www.example.com'/>"}
    let(:note_with_linkgrp) {"<linkgrp linktype='extended'><extrefloc href='http://www.someserver.edu/findaids/3270.xml'><archref>archref</archref></extrefloc><extrefloc href='http://www.someserver.edu/findaids/9248.xml'><archref>archref</archref></extrefloc></linkgrp>"}
    let(:note_with_ptr) {"<ptr linktype='simple' actuate='onrequest' show='replace' target='mss1982-062_add2'/>"}
    let(:note_with_ptrloc) {"<ptrloc audience='external'/>"}
    let(:note_with_ref) {"<ref linktype='simple' target='NonC:21-2' show='replace' actuate='onrequest'>"}
    let(:note_with_refloc) {"<refloc target='a9'></refloc>"}
    let(:note_with_resource) {"<resource linktype='resource' label='start'/>"}
    let(:note_with_title) {"<title render='italic'/>"}
    let(:note_with_extref) { "<extref linktype='simple' entityref='site' title='title' actuate='onrequest' show='new' href='http://duckduckgo.com'>A Good Search Engine</p>" }
    let(:note_with_linebreaks) { "Something, something,\n\nsomething." }
    let(:note_with_linebreaks_and_good_mixed_content) { "Something, something,\n\n<bioghist>something.</bioghist>\n\n" }
    let(:note_with_linebreaks_and_evil_mixed_content) { "Something, something,\n\n<bioghist>something.\n\n</bioghist>\n\n" }
    let(:note_with_linebreaks_but_something_xml_nazis_hate) { "Something, something,\n\n<prefercite>XML & How to Live it!</prefercite>\n\n" }
    let(:note_with_linebreaks_and_xml_namespaces) { "Something, something,\n\n<prefercite xlink:foo='one' ns2:bar='two' >XML, you so crazy!</prefercite>\n\n" }
    let(:note_with_smart_quotes) {"This note has “smart quotes” and ‘smart apostrophes’ from MSWord."}
    let(:note_with_different_amps) {"The materials are arrange in folders. Mumford&Sons. Mumford & Sons. They are cool&hip. &lt;p&gt;foo, 2 & 2.&lt;/p&gt;"}
    let(:serializer) { EADSerializer.new }

    it "can strip <p> tags from content when disallowed" do
      expect(serializer.strip_p(note_with_p)).to eq("A NOTE!")
    end

    it "adds xlink prefix to attributes in mixed content" do
      expect(serializer.add_xlink_prefix(note_with_extref)).to eq("<extref linktype='simple' entityref='site' xlink:title='title' xlink:actuate='onrequest' xlink:show='new' xlink:href='http://duckduckgo.com'>A Good Search Engine</p>")
      expect(serializer.add_xlink_prefix(note_with_archref)).to eq("<archref audience='external'/>")
      expect(serializer.add_xlink_prefix(note_with_bibref)).to eq("<bibref audience='internal'/>")
      expect(serializer.add_xlink_prefix(note_with_extptr)).to eq("<extptr linktype='simple' entityref='entref' xlink:title='title' xlink:show='embed'/>")
      expect(serializer.add_xlink_prefix(note_with_extptrloc)).to eq("<extptrloc xlink:href='http://www.example.com'/>")
      expect(serializer.add_xlink_prefix(note_with_extrefloc)).to eq("<extrefloc xlink:href='http://www.example.com'/>")
      expect(serializer.add_xlink_prefix(note_with_linkgrp)).to eq("<linkgrp linktype='extended'><extrefloc xlink:href='http://www.someserver.edu/findaids/3270.xml'><archref>archref</archref></extrefloc><extrefloc xlink:href='http://www.someserver.edu/findaids/9248.xml'><archref>archref</archref></extrefloc></linkgrp>")
      expect(serializer.add_xlink_prefix(note_with_ptr)).to eq("<ptr linktype='simple' xlink:actuate='onrequest' xlink:show='replace' target='mss1982-062_add2'/>")
      expect(serializer.add_xlink_prefix(note_with_ptrloc)).to eq("<ptrloc audience='external'/>")
      expect(serializer.add_xlink_prefix(note_with_ref)).to eq("<ref linktype='simple' target='NonC:21-2' xlink:show='replace' xlink:actuate='onrequest'>")
      expect(serializer.add_xlink_prefix(note_with_refloc)).to eq("<refloc target='a9'></refloc>")
      expect(serializer.add_xlink_prefix(note_with_resource)).to eq("<resource linktype='resource' label='start'/>")
      expect(serializer.add_xlink_prefix(note_with_title)).to eq("<title render='italic'/>")
    end

    it "does not add xlink prefix when mixed content has no attributes" do
      expect(serializer.add_xlink_prefix(note_with_p)).to eq(note_with_p)
    end

    it "can leave <p> tags in content" do
      expect(serializer.handle_linebreaks(note_with_p)).to eq(note_with_p)
    end

    it "will add <p> tags to content with linebreaks" do
      expect(serializer.handle_linebreaks(note_with_linebreaks)).to eq("<p>Something, something,</p><p>something.</p>")
    end

    it "will add <p> tags to content with linebreaks and mixed content" do
      expect(serializer.handle_linebreaks(note_with_linebreaks_and_good_mixed_content)).to eq("<p>Something, something,</p><p><bioghist>something.</bioghist></p>")
    end

    it "will return original content when linebreaks and mixed content produce invalid markup" do
      expect(serializer.handle_linebreaks(note_with_linebreaks_and_evil_mixed_content)).to eq(note_with_linebreaks_and_evil_mixed_content)
    end

    it "will add <p> tags to content with linebreaks and mixed content even if those evil &'s are present in the text" do
      expect(serializer.handle_linebreaks(note_with_linebreaks_but_something_xml_nazis_hate)).to eq("<p>Something, something,</p><p><prefercite>XML &amp; How to Live it!</prefercite></p>")
    end

    it "will add <p> tags to content with linebreaks and mixed content even there are weird namespace prefixes" do
      expect(serializer.handle_linebreaks(note_with_linebreaks_and_xml_namespaces)).to eq("<p>Something, something,</p><p><prefercite xlink:foo='one' ns2:bar='two' >XML, you so crazy!</prefercite></p>")
    end

    it "will correctly handle content with & as punctuation as well as & as pre-escaped characters" do
      expect(serializer.handle_linebreaks(note_with_different_amps)).to eq("<p>The materials are arrange in folders. Mumford&amp;Sons. Mumford &amp; Sons. They are cool&amp;hip. &lt;p&gt;foo, 2 &amp; 2.&lt;/p&gt;</p>")
    end

    it "will replace MSWord-style smart quotes with ASCII characters" do
      expect(serializer.remove_smart_quotes(note_with_smart_quotes)).to eq("This note has \"smart quotes\" and \'smart apostrophes\' from MSWord.")
    end

    context 'when revision statement starts with mixed content' do
      let(:resource) do
        create(:json_resource,
          :publish => true,
          :revision_statements => [
            {
              :date => '1999-9-9',
              :description => '<change><date>9/9/99</date><item>mixed content revision</item></change>',
              :publish => true
            },
            {
              :date => '1999-9-9',
              :description => '<name>revision name</name> that made some changes',
              :publish => true
            }
          ]
        )
      end

      it "properly exports revisiondesc starting with mixed content" do
        document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
        document.remove_namespaces!
        expect(document.xpath('//revisiondesc/change').length).to eq(2)
      end
    end

    context 'when revision statement fields contain ampersand' do
      let(:resource) do
        create(:json_resource,
          :publish => true,
          :revision_statements => [
            {
              :date => 'date1&date1',
              :description => '111111111&111111111',
              :publish => true
            },
            {
              :date => 'date2 & date2',
              :description => '222222222 & 222222222',
              :publish => true
            }
          ]
        )
      end

      it "replaces ampersand with &amp; for revsion statement" do
        document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
        document_xml_string = document.to_xml

        expect(document_xml_string).to_not include 'date1&date1'
        expect(document_xml_string).to include 'date1&amp;date1'

        expect(document_xml_string).to_not include '111111111&111111111'
        expect(document_xml_string).to include '111111111&amp;111111111'

        expect(document_xml_string).to_not include 'date2 & date2'
        expect(document_xml_string).to include 'date2 &amp; date2'

        expect(document_xml_string).to_not include '222222222 & 222222222'
        expect(document_xml_string).to include '222222222 &amp; 222222222'
      end
    end

    context 'when revision statement fields contain escaped ampersand in the form of &amp;' do
      let(:resource) do
        create(:json_resource,
          :publish => true,
          :revision_statements => [
            {
              :date => 'date1&amp;date1',
              :description => '111111111&amp;111111111',
              :publish => true
            },
            {
              :date => 'date2 &amp; date2',
              :description => '222222222 &amp; 222222222',
              :publish => true
            }
          ]
        )
      end

      it "does not affect the &amp; for revsion statement" do
        document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
        document_xml_string = document.to_xml

        expect(document_xml_string).to_not include 'date1&amp;amp;date1'
        expect(document_xml_string).to include 'date1&amp;date1'

        expect(document_xml_string).to_not include '111111111&amp;amp;111111111'
        expect(document_xml_string).to include '111111111&amp;111111111'

        expect(document_xml_string).to_not include 'date2 &amp;amp; date2'
        expect(document_xml_string).to include 'date2 &amp; date2'

        expect(document_xml_string).to_not include '222222222 &amp;amp; 222222222'
        expect(document_xml_string).to include '222222222 &amp; 222222222'
      end
    end

    context 'when finding_aid_language_note contains an ampersand character' do
      context 'when ampersand is not surrounded with spaces' do
        let(:resource) do
          create(:json_resource,
            :publish => true,
            :finding_aid_language_note => 'finding_aid_language_note&finding_aid_language_note'
          )
        end

        it "replaces ampersand with &amp;" do
          document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
          document_xml_string = document.to_xml

          expect(document_xml_string).to include 'finding_aid_language_note&amp;finding_aid_language_note'
          expect(document_xml_string).to_not include 'finding_aid_language_note&finding_aid_language_note'
        end
      end

      context 'when ampersand is surrounded with spaces' do
        let(:resource) do
          create(:json_resource,
            :publish => true,
            :finding_aid_language_note => 'finding_aid_language_note & finding_aid_language_note'
          )
        end

        it "replaces ampersand with &amp;" do
          document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
          document_xml_string = document.to_xml

          expect(document_xml_string).to include 'finding_aid_language_note &amp; finding_aid_language_note'
          expect(document_xml_string).to_not include 'finding_aid_language_note & finding_aid_language_note'
        end
      end
    end

    context 'when finding_aid_language_note contains an escaped ampersand character in the form of &amp;' do
      context 'when &amp; is not surrounded with spaces' do
        let(:resource) do
          create(:json_resource,
            :publish => true,
            :finding_aid_language_note => 'finding_aid_language_note&amp;finding_aid_language_note'
          )
        end

        it "does not replace ampersand with &amp;" do
          document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
          document_xml_string = document.to_xml

          expect(document_xml_string).to include 'finding_aid_language_note&amp;finding_aid_language_note'
          expect(document_xml_string).to_not include 'finding_aid_language_note&amp;amp;finding_aid_language_note'
        end
      end

      context 'when ampersand is surrounded with spaces' do
        let(:resource) do
          create(:json_resource,
            :publish => true,
            :finding_aid_language_note => 'finding_aid_language_note &amp; finding_aid_language_note'
          )
        end

        it "does not replace ampersand with &amp;" do
          document = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{resource.id}.xml")
          document_xml_string = document.to_xml

          expect(document_xml_string).to include 'finding_aid_language_note &amp; finding_aid_language_note'
          expect(document_xml_string).to_not include 'finding_aid_language_note &amp;amp; finding_aid_language_note'
        end
      end
    end
  end

  describe "Test unpublished record EAD exports" do

    def get_xml_doc(include_unpublished = false)
      as_test_user("admin") do
        DB.open(true) do
          doc_for_unpublished_resource = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@unpublished_resource_jsonmodel.id}.xml?include_unpublished=#{include_unpublished}&include_daos=true&include_uris=true", true)

          doc_nsless_for_unpublished_resource = Nokogiri::XML::Document.parse(doc_for_unpublished_resource)
          doc_nsless_for_unpublished_resource.remove_namespaces!

          return doc_nsless_for_unpublished_resource
        end
      end
    end

    before(:all) {
      as_test_user('admin', true) do
        RSpec::Mocks.with_temporary_scope do
          # EAD export normally tries the search index first, but for the tests we'll
          # skip that since Solr isn't running.
          allow(Search).to receive(:records_for_uris) do |*|
            {'results' => []}
          end

          @unpublished_agent = create(:json_agent_person, :publish => false)

          unpublished_resource = create(:json_resource,
                                        :publish => false,
                                        :finding_aid_status => 'in_progress',
                                        :is_finding_aid_status_published => false,
                                        :linked_agents => [{
                                          :ref => @unpublished_agent.uri,
                                          :role => 'creator'
                                        }],
                                        :revision_statements => [
                                          {
                                            :date => 'some date',
                                            :description => 'unpublished revision statement',
                                            :publish => false
                                          },
                                          {
                                            :date => 'some date',
                                            :description => 'published revision statement',
                                            :publish => true
                                          }
                                        ])

          @unpublished_resource_jsonmodel = JSONModel(:resource).find(unpublished_resource.id)

          @published_archival_object = create(:json_archival_object,
                                              :resource => {:ref => @unpublished_resource_jsonmodel.uri},
                                              :publish => true)

          @unpublished_archival_object = create(:json_archival_object,
                                                :resource => {:ref => @unpublished_resource_jsonmodel.uri},
                                                :publish => false)

          @xml_including_unpublished = get_xml_doc(include_unpublished = true)
          @xml_not_including_unpublished = get_xml_doc(include_unpublished = false)
          raise Sequel::Rollback
        end
      end
    }

    it "does not set <ead> attribute audience 'internal' when resource is published" do
      expect(@doc_nsless.at_xpath('//ead')).not_to have_attribute('audience', 'internal')
    end

    it "sets <ead> attribute audience 'internal' when resource is not published" do
      expect(@xml_including_unpublished.at_xpath('//ead')).to have_attribute('audience', 'internal')
      expect(@xml_not_including_unpublished.at_xpath('//ead')).to have_attribute('audience', 'internal')
    end

    it "includes unpublished items when include_unpublished option is false" do
      expect(@xml_including_unpublished.xpath('//c').length).to eq(2)
      expect(@xml_including_unpublished.xpath("//c[@id='aspace_#{@published_archival_object.ref_id}'][not(@audience='internal')]").length).to eq(1)
      expect(@xml_including_unpublished.xpath("//c[@id='aspace_#{@unpublished_archival_object.ref_id}'][@audience='internal']").length).to eq(1)

      header = @xml_including_unpublished.xpath('//eadheader')
      expect(header).to have_attribute('findaidstatus')
    end

    it "does not include unpublished items when include_unpublished option is false" do
      items = @xml_not_including_unpublished.xpath('//c')
      expect(items.length).to eq(1)

      item = items.first
      expect(item).not_to have_attribute('audience', 'internal')

      header = @xml_not_including_unpublished.xpath('//eadheader')
      expect(item).not_to have_attribute('findaidstatus')
    end

    it "include the unpublished agent with audience internal when include_unpublished is true" do
      creators = @xml_including_unpublished.xpath('//origination')
      expect(creators.length).to eq(1)
      creator = creators.first
      expect(creator).to have_attribute('label', 'Creator')
      expect(creator).to have_attribute('audience', 'internal')
    end

    it "does not include the unpublished agent with audience internal when include_unpublished is false" do
      creators = @xml_not_including_unpublished.xpath('//origination')
      expect(creators.length).to eq(0)
    end

    it "include the unpublished revision statement with audience internal when include_unpublished is true" do
      revision_statements = @xml_including_unpublished.xpath('//revisiondesc/change')
      expect(revision_statements.length).to eq(2)
      unpublished = revision_statements.first
      expect(unpublished).to have_attribute('audience', 'internal')
      items = @xml_including_unpublished.xpath('//revisiondesc/change/item')
      expect(items.length).to eq(2)
      expect(items.first).to have_inner_text('unpublished revision statement')
    end

    it "does not set <change> attribute audience 'internal' when revision statement is published" do
      revision_statements = @xml_including_unpublished.xpath('//revisiondesc/change')
      expect(revision_statements.length).to eq(2)
      published = revision_statements[1]
      expect(published).not_to have_attribute('audience', 'internal')
      items = @xml_including_unpublished.xpath('//revisiondesc/change/item')
      expect(items.length).to eq(2)
      expect(items[1]).to have_inner_text('published revision statement')
    end

    it "includes only the published revision statement when include_unpublished is false" do
      revision_statements = @xml_not_including_unpublished.xpath('//revisiondesc/change')
      expect(revision_statements.length).to eq(1)
      items = @xml_not_including_unpublished.xpath('//revisiondesc/change/item')
      expect(items.length).to eq(1)
      expect(items.first).to have_inner_text('published revision statement')
    end
  end

  describe "Test suppressed record EAD exports" do

    def get_xml_doc
      as_test_user("admin") do
        DB.open(true) do
          doc_for_resource = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource_jsonmodel.id}.xml?include_unpublished=true&include_daos=true&include_uris=true", true)

          doc_nsless_for_resource = Nokogiri::XML::Document.parse(doc_for_resource)
          doc_nsless_for_resource.remove_namespaces!

          return doc_nsless_for_resource
        end
      end
    end


    before(:all) {
      as_test_user('admin', true) do
        RSpec::Mocks.with_temporary_scope do
          # EAD export normally tries the search index first, but for the tests we'll
          # skip that since Solr isn't running.
          allow(Search).to receive(:records_for_uris) do |*|
            {'results' => []}
          end

          resource = create(:json_resource,
                            :publish => false)

          @resource_jsonmodel = JSONModel(:resource).find(resource.id)

          @suppressed_series = create(:json_archival_object,
                                      :resource => {:ref => @resource_jsonmodel.uri},
                                      :publish => true,
                                      :suppressed => true)

          @unsuppressed_series = create(:json_archival_object,
                                        :resource => {:ref => @resource_jsonmodel.uri},
                                        :publish => true,
                                        :suppressed => false)

          @suppressed_series_unsuppressedchild = create(:json_archival_object,
                                                        :resource => {:ref => @resource_jsonmodel.uri},
                                                        :parent => {:ref => @suppressed_series.uri},
                                                        :publish => true,
                                                        :suppressed => false)

          @unsuppressed_series_unsuppressed_child = create(:json_archival_object,
                                                           :resource => {:ref => @resource_jsonmodel.uri},
                                                           :parent => {:ref => @unsuppressed_series.uri},
                                                           :publish => true,
                                                           :suppressed => false)

          @unsuppressed_series_suppressed_child = create(:json_archival_object,
                                                         :resource => {:ref => @resource_jsonmodel.uri},
                                                         :parent => {:ref => @unsuppressed_series.uri},
                                                         :publish => true,
                                                         :suppressed => true)

          @xml = get_xml_doc
          raise Sequel::Rollback
        end
      end
    }

    it "excludes suppressed items" do
      expect(@xml.xpath('//c').length).to eq(2)
      expect(@xml.xpath("//c[@id='aspace_#{@unsuppressed_series.ref_id}']").length).to eq(1)
      expect(@xml.xpath("//c[@id='aspace_#{@unsuppressed_series_unsuppressed_child.ref_id}']").length).to eq(1)
    end
  end

  # See ANW-1282
  describe "Metadata Rights Declaration mappings " do
    it "maps all subrecords to ead/control/filedesc/publicationstmt" do
      subrecord = @resource.metadata_rights_declarations[0]
      license_translation = I18n.t("enumerations.metadata_license.#{subrecord['license']}")
      expect(@doc).to have_tag("eadheader/filedesc/publicationstmt/p[text() = '#{license_translation}']")
    end
  end

  describe "ARKs" do
    def get_xml_doc
      as_test_user("admin") do
        DB.open(true) do
          doc_for_resource = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_unpublished=true&include_daos=true&include_uris=true", true)

          doc_nsless_for_resource = Nokogiri::XML::Document.parse(doc_for_resource)
          doc_nsless_for_resource.remove_namespaces!

          return doc_nsless_for_resource
        end
      end
    end

    before(:all) do
      @pre_arks_enabled = AppConfig[:arks_enabled]

      AppConfig[:arks_enabled] = true
      RequestContext.open(:repo_id => $repo_id) do
        as_test_user('admin', true) do
          RSpec::Mocks.with_temporary_scope do
            # EAD export normally tries the search index first, but for the tests we'll
            # skip that since Solr isn't running.
            allow(Search).to receive(:records_for_uris) do |*|
              {'results' => []}
            end

            @resource = create(:json_resource)
            @child = create(:json_archival_object, :resource => {:ref => @resource.uri})

            # Change the ARK-naan to populate a second ARK for the records
            # and create a "historic" ARK
            pre_ark_naan = AppConfig[:ark_naan]
            AppConfig[:ark_naan] = SecureRandom.hex
            ArkName.ensure_ark_for_record(Resource[@resource.id], nil)
            ArkName.ensure_ark_for_record(ArchivalObject[@child.id], nil)
            AppConfig[:ark_naan] = pre_ark_naan

            @xml_with_arks_enabled = get_xml_doc

            @resource_json = Resource.to_jsonmodel(@resource.id)
            @child_json = ArchivalObject.to_jsonmodel(@child.id)

            AppConfig[:arks_enabled] = false
            @xml_with_arks_disabled = get_xml_doc

            raise Sequel::Rollback
          end
        end
      end
    end

    after(:all) do
      AppConfig[:arks_enabled] = @pre_arks_enabled
    end

    describe("when enabled") do
      it "maps ARK URL to eadid/@url" do
        expect(@xml_with_arks_enabled.xpath('//eadheader/eadid').first.get_attribute('url')).to eq(@resource_json.ark_name['current'])
      end

      it "includes current ARK as unitid for resource" do
        expect(@xml_with_arks_enabled.xpath('//archdesc/did/unitid[@type="ark"]').length).to eq(1)
        expect(@xml_with_arks_enabled.xpath('//archdesc/did/unitid[@type="ark"]/extref').first.get_attribute('href')).to eq(@resource_json.ark_name['current'])
      end

      it "includes previous ARK as unitid for resource" do
        expect(@xml_with_arks_enabled.xpath('//archdesc/did/unitid[@type="ark-superseded"]').length).to eq(1)
        expect(@xml_with_arks_enabled.xpath('//archdesc/did/unitid[@type="ark-superseded"]/extref').first.get_attribute('href')).to eq(@resource_json.ark_name['previous'].first)
      end

      it "includes current ARK as unitid for archival object" do
        expect(@xml_with_arks_enabled.xpath('//archdesc/dsc/c/did/unitid[@type="ark"]').length).to eq(1)
        expect(@xml_with_arks_enabled.xpath('//archdesc/dsc/c/did/unitid[@type="ark"]/extref').first.get_attribute('href')).to eq(@child_json.ark_name['current'])
      end

      it "includes previous ARK as unitid for archival object" do
        expect(@xml_with_arks_enabled.xpath('//archdesc/dsc/c/did/unitid[@type="ark-superseded"]').length).to eq(1)
        expect(@xml_with_arks_enabled.xpath('//archdesc/dsc/c/did/unitid[@type="ark-superseded"]/extref').first.get_attribute('href')).to eq(@child_json.ark_name['previous'].first)
      end
    end

    describe("when disabled") do
      it "maps resource.ead_location to eadid/@url" do
        expect(@xml_with_arks_disabled.xpath('//eadheader/eadid').first.get_attribute('url')).to eq(@resource_json.ead_location)
      end

      it "doesn't include any unitid/@type of 'ark' or 'ark-superseded'" do
        expect(@xml_with_arks_disabled.xpath('//archdesc/did/unitid[@type="ark"]').length).to eq(0)
        expect(@xml_with_arks_disabled.xpath('//archdesc/did/unitid[@type="ark-superseded"]').length).to eq(0)
        expect(@xml_with_arks_disabled.xpath('//archdesc/dsc/c/did/unitid[@type="ark"]').length).to eq(0)
        expect(@xml_with_arks_disabled.xpath('//archdesc/dsc/c/did/unitid[@type="ark-superseded"]').length).to eq(0)
      end
    end
  end
end
