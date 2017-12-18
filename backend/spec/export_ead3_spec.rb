# encoding: utf-8
require 'nokogiri'
require 'spec_helper'
require_relative 'export_spec_helper'

describe "EAD3 export mappings" do

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
                                                   build(:json_note_definedlist,{  :publish => true, :title => "note_definedlist",
                                                           :items => [
                                                                      {:label => "First Mate", :value => "<persname encodinganalog='600$a' source='lcnaf'><part>Gilligan</part></persname>" },
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
                      :finding_aid_series_statement => "here is the series statement",
                      :publish => true,
                      )

    @resource = JSONModel(:resource).find(resource.id, 'resolve[]' => 'top_container')

    @archival_objects = {}

    10.times {
      parent = [true, false].sample ? @archival_objects.keys[rand(@archival_objects.keys.length)] : nil
      a = create(:json_archival_object_normal,  :resource => {:ref => @resource.uri},
                 :parent => parent ? {:ref => parent} : nil,
                 :notes => build_archival_object_notes(5),
                 :linked_agents => build_linked_agents(@agents),
                 :instances => [build(:json_instance_digital),
                                build(:json_instance,
                                      :sub_container => build(:json_sub_container,
                                                              :top_container => {:ref => @top_container.uri}))
                               ],
                 :subjects => @subjects.map{|ref, s| {:ref => ref}}.shuffle,
                 :publish => true,
                 )

      a = JSONModel(:archival_object).find(a.id, 'resolve[]' => 'top_container')

      @archival_objects[a.uri] = a
    }
  end


  def mt(*args)

    raise "XML document not loaded" unless @doc && @doc_nsless

    doc_to_test = ( args[1] && args[1].match(/\/xmlns:[\w]+/) ) ? @doc : @doc_nsless

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
    RSpec::Mocks.with_temporary_scope do
      # EAD export normally tries the search index first, but for the tests we'll
      # skip that since Solr isn't running.
      allow(Search).to receive(:records_for_uris) do |*|
        {'results' => []}
      end

      as_test_user("admin") do
        DB.open(true) do
          load_export_fixtures
          @doc = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource.id}.xml?include_unpublished=true&include_daos=true&ead3=true")
          @doc_nsless = Nokogiri::XML::Document.parse(@doc.to_xml)
          @doc_nsless.remove_namespaces!
          raise Sequel::Rollback
        end
      end
    end




    # @doc.errors.length.should == 0




    # if the word Nokogiri appears in the XML file, we'll assume something
    # has gone wrong
    @doc.to_xml.should_not include("Nokogiri")
    @doc.to_xml.should_not include("#&amp;")
    @doc.to_xml.should_not include("ASPACE EXPORT ERROR")
  end


  let(:repo) { JSONModel(:repository).find($repo_id) }



  describe "/control mappings" do


    it "maps resource.finding_aid_status to @finding_aid_status" do
      {
        'repositoryencoding' => "iso15511",
        'countryencoding' => "iso3166-1",
        'dateencoding' => "iso8601",
        'langencoding' => "iso639-2b"
      }.each do |tag, val|
        mt(val, "//control", tag)
      end
    end

    it "maps resource.ead_id to recordid" do
      mt(@resource.ead_id, "control/recordid")
    end

    it "maps resource.ead_location to recordid/@instanceurl" do
      mt(@resource.ead_location, "control/recordid", 'instanceurl')
    end

    it "maps resource.finding_aid_title to filedesc/titlestmt/titleproper" do
      mt(@resource.finding_aid_title, "control/filedesc/titlestmt/titleproper[not(@type)]")
    end

    it "maps resource.finding_aid_filing_title to filedesc/titlestmt/titleproper[@localtype == 'filing']" do
      mt(@resource.finding_aid_filing_title, "control/filedesc/titlestmt/titleproper[@localtype='filing']")
    end

    it "maps resource.finding_aid_author to filedesc/titlestmt/author" do
      data = @resource.finding_aid_author ? "Finding aid prepared by #{@resource.finding_aid_author}" : nil
      mt(data, "control/filedesc/titlestmt/author")
    end

    it "maps resource.finding_aid_sponsor to filedesc/titlestmt/sponsor" do
      mt(@resource.finding_aid_sponsor, "control/filedesc/titlestmt/sponsor")
    end

    it "maps resource.finding_aid_edition_statement to filedesc/editionstmt/p/finding_aid_edition_statement" do
      mt(@resource.finding_aid_edition_statement, "control/filedesc/editionstmt/p/finding_aid_edition_statement")
    end

    it "maps repository.name to filedesc/publicationstmt/publisher" do
      mt(repo.name, "control/filedesc/publicationstmt/publisher")
    end

    it "maps resource.(id_0|id_1|id_2|id_3) to filedesc/publicationstmt/num" do
      mt((0..3).map{|i| @resource.send("id_#{i}")}.compact.join('.'), "control/filedesc/publicationstmt/num")
    end

    it "maps repository.country and repository.org_code to maintenanceagency/agencycode" do
      # data = (repo.country && repo.org_code) ? "#{repo.country}-#{repo.org_code}" : nil

      data = "#{repo.country}-#{repo.org_code}"

      mt(data, "control/maintenanceagency/agencycode")
    end



    # it "maps repository.country to eadid/@countrycode" do
    #   mt(repo.country, "control/eadid", "countrycode")
    # end


    describe "repository.agent.agent_contacts[0] to filedesc/publicationstmt/address/ mappings" do
      let(:path) { "control/filedesc/publicationstmt/address/" }
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


    it "maps repository.image_url to filedesc/publicationstmt/p/ptr@href" do
      if repo.image_url
        {
          repo.image_url => "href",
          "onload" => "actuate",
          "embed" => "show"
        }.each do |data, att|
          mt(data, "control/filedesc/publicationstmt/p/ptr", att)
        end
      else
        mt(nil, "control/filedesc/publicationstmt/p/ptr")
      end
    end


    it "maps resource.finding_aid_date to filedesc/publicationstmt/date" do
      mt(@resource.finding_aid_date, "control/filedesc/publicationstmt/date")
    end


    it "maps resource.finding_aid_series_statement to filedesc/seriesstmt" do
      mt(@resource.finding_aid_series_statement, "control/filedesc/seriesstmt")
    end


    it "maps resource.finding_aid_note to filedesc/notestmt/controlnote" do
      mt(@resource.finding_aid_note, "control/filedesc/notestmt/controlnote")
    end


    it "produces a creation statement and timestamp at maintenancehistory/maintenanceevent" do
      # date_regex = '\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\s?[-+]?\d*'
      date_regex = '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\s?[-+]?\d*:\d*'
      # full_regex = 'This finding aid was produced using ArchivesSpace on '+date_regex+'\.'
      description_regex = 'This finding aid was produced using ArchivesSpace on'
      mt(Regexp.new(description_regex), "//control/maintenancehistory/maintenanceevent/eventdescription")
      mt(Regexp.new(date_regex), "//control/maintenancehistory/maintenanceevent/eventdatetime")
    end


    it "maps resource.finding_aid_description_rules to conventiondeclaration" do
      data = @resource.finding_aid_description_rules ? translate('enumerations.resource_finding_aid_description_rules', @resource.finding_aid_description_rules) : nil
      mt(data, "control/conventiondeclaration/citation")
    end


    it "maps resource.revision_statements.date to maintenancehistory/maintenanceevent/eventdatetime" do
      mt(@resource.revision_statements[0]["date"].to_s, "control/maintenancehistory/maintenanceevent[2]/eventdatetime")
    end


    it "maps resource.finding_aid_revision_description to maintenancehistory/maintenanceevent/eventdescription" do
      mt(@resource.revision_statements[0]["description"], "control/maintenancehistory/maintenanceevent[2]/eventdescription")
    end


    it "maps resource.finding_aid_language to profiledesc/language" do
      mt(@resource.finding_aid_language, "control/languagedeclaration/language")
    end


  end



  # Examples used by resource and archival_objects
  shared_examples "archival object desc mappings" do


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




    describe "How {archival_object}.instances[].sub_container data is mapped." do
      let(:instances) { object.instances.reject {|i| i['sub_container'].nil? } }

      it "maps {archival_object}.instances[].sub_container to {desc_path}/did/container" do
        container_ix = 1

        instances.each do |inst|
          # increment 1 for the top_container
          container_ix += 1

          sub = inst['sub_container']
          if sub['type_2']
            mt(sub['type_2'], "#{desc_path}/did/container[#{container_ix}]", "localtype")
            mt(sub['indicator_2'], "#{desc_path}/did/container[#{container_ix}]")
            container_ix += 1
          end

          if sub['type_3']
            mt(sub['type_3'], "#{desc_path}/did/container[#{container_ix}]", "localtype")
            mt(sub['indicator_3'], "#{desc_path}/did/container[#{container_ix}]")
            container_ix += 1
          end
        end
      end


      it "maps {archival_object}.instance[].instance_type to {desc_path}/did/container@label" do
        container_ix = 1

        instances.each do |inst|
          sub = inst['sub_container']
          top = sub['top_container']['_resolved']

          mt(top['indicator'], "#{desc_path}/did/container[#{container_ix}]")

          label = translate('enumerations.instance_instance_type', inst['instance_type'])
          mt(label, "#{desc_path}/did/container[#{container_ix}]", "label")

          container_ix += 1

          # skip the children
          container_ix += 1 if sub['type_2']
          container_ix += 1 if sub['type_3']
        end
      end


      it "maps {archival_object}.instance[].sub_container.top_container.barcode to {desc_path}/did/container@containerid" do
        container_ix = 1

        instances.each do |inst|
          sub = inst['sub_container']
          top = sub['top_container']['_resolved']
          mt(top['barcode'], "#{desc_path}/did/container[#{container_ix}]", "containerid")
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

        if ext['number']
          mt(ext['number'], "#{desc_path}/did/physdescstructured[#{count}]/quantity")
        end

        if ext['extent_type']
          extent_type = translate('enumerations.extent_extent_type', ext['extent_type'])
          mt(extent_type, "#{desc_path}/did/physdescstructured[#{count}]/unittype")
        end

        # if ext['number'] && ext['extent_type']
        #   data = "#{ext['number']} #{translate('enumerations.extent_extent_type', ext['extent_type'])}"
        #   mt(data, "#{desc_path}/did/physdesc[#{count}]/extent[@altrender='materialtype spaceoccupied']")
        # end

        if ext['dimensions']
          mt(ext['dimensions'], "#{desc_path}/did/physdescstructured[#{count}]/dimensions")
        end

        if ext['physical_details']
          mt(ext['physical_details'], "#{desc_path}/did/physdescstructured[#{count}]/physfacet")
        end

        if ext['container_summary']
          mt(ext['container_summary'], "#{desc_path}/did/physdesc[#{count}]")
        end

        count += 1
      end
    end



    it "maps structured {archival_object}.date to {desc_path}/did/unitdatestructured and applies correct attributes" do
      count = 1
      object.dates.each do |date|

        if date['begin'] && date['date_type'] == 'single'

          path = "#{desc_path}/did/unitdatestructured[#{count}]/datesingle"
          standarddate = date['begin']
          value = date['expression'] ? date['expression'] : date['begin']

          mt(standarddate, path, 'standarddate')
          mt(value, path)

          count += 1

        elsif (date['begin'] || date['end']) && date['date_type'] != 'single'
          unitdatestructured_path = "#{desc_path}/did/unitdatestructured[#{count}]"

          daterange_path = unitdatestructured_path + "/daterange"

          if date['certainty']
            mt(date['certainty'], unitdatestructured_path, 'certainty')
          end

          if date['era']
            mt(date['era'], unitdatestructured_path, 'era')
          end

          if date['calendar']
            mt(date['calendar'], unitdatestructured_path, 'calendar')
          end

          if date['begin']
            path = daterange_path + '/fromdate'
            value = date['begin']
            mt(value, path)
            mt(value, path, 'standarddate')
          end

          if date['end']
            path = daterange_path + '/todate'
            value = date['end']
            mt(value, path)
            mt(value, path, 'standarddate')
          end

          count += 1


        end


      end
    end




    it "maps date expression to {archival_object}.date to {desc_path}/did/unitdate when present along with both start and end dates" do
      count = 1
      object.dates.each do |date|
        if date['begin'] && date['end'] && date['expression']
          path = "#{desc_path}/did/unitdate[#{count}]"
          value = date['expression']
          mt(value, path)
          count += 1
        end
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


      # it "maps notes of type 'dimensions' to did/physdesc" do
      #   notes.select {|n| n['type'] == 'dimensions'}.each_with_index do |note, i|
      #     content = note_content(note)
      #     path = "#{desc_path}/did/physdesc[text()='#{content}']"
      #     mt(content.gsub("<p>",'').gsub("</p>", ""), path, :markup)
      #     if note['persistent_id']
      #       mt("aspace_" + note['persistent_id'], path, "id")
      #     else
      #       mt(nil, path, "id")
      #     end
      #   end
      # end


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


      it "maps notes of type 'physfacet' to did/physdesc" do
        notes.select {|n| n['type'] == 'physfacet'}.each_with_index do |note, i|
          content = note_content(note)
          path = "#{desc_path}/did/physdesc[text()='#{content}']"
          if !note['persistent_id'].nil?
            mt("aspace_" + note['persistent_id'], path, "id")
          else
            mt(nil, path, "id")
          end
        end
      end


      # it "maps notes of type 'langmaterial' to did/langmaterial/language" do
      #   notes.select {|n| n['type'] == 'langmaterial'}.each_with_index do |note, i|
      #     content = note_content(note)
      #     path = "#{desc_path}/did/langmaterial[#{i+1}]/language"
      #     mt(note_content(note), path)

      #     if note['persistent_id']
      #       mt("aspace_" + note['persistent_id'], path, "id")
      #     else
      #       mt(nil, path, "id")
      #     end

      #   end
      # end


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
          path += "[@id='#{id}']"
          full_path = "#{desc_path}/#{path}"

          if !note['persistent_id'].nil?
            mt(id, full_path, 'id')
          else
            mt(nil, full_path, 'id')
          end
          mt(head_text, "#{full_path}/head")

          mt(content, "./#{path}/p")

          note['items'].each_with_index do |item, i|
            mt(item, "#{full_path}/bibref[#{i+1}]")
          end
        end
      end


      it "maps notes[].note_index to {desc_path}/index" do
        indexes.each do |note|
          head_text = note['label']

          # id = "aspace_" + note['persistent_id']

          content = note_content(note)

          if note['persistent_id']
            id = "aspace_" + note['persistent_id']
            path = "index[@id='#{id}']"
            full_path = "#{desc_path}/#{path}"

            # path += id ? "[@id='#{id}']" : "[p[contains(text(), '#{content}')]]"

            mt(id, full_path, 'id')
          else
            full_path = "#{desc_path}/index"
            mt(nil, full_path, 'id')
          end

          mt(head_text, "#{full_path}/head")

          mt(content, "#{full_path}/p")

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
              mt(item['event_date'], "#{item_path}/datesingle")

              next unless item.has_key?('events')
              item['events'].each_with_index do |event, k|
                event_path = "#{item_path}/chronitemset/event[#{k+1}]"
                # Nokogiri 'helpfully' reads "&amp;" into "&" when it parses the doc
                mt(event.gsub("&amp;", "&"), event_path)
              end
            end
          end
        end
      end


      it "maps subnotes[].note_orderedlist to NOTE_PATH/list[@listtype='ordered']" do
        multis.each do |note|
          orderedlists = get_subnotes_by_type(note, 'note_orderedlist')
          next if orderedlists.empty?

          ppath = build_path.call(note)

          orderedlists.each_with_index do |ol, i|
            ol_path = "#{ppath}/list[@listtype='ordered'][#{i+1}]"

            mt(ol['enumeration'], ol_path, 'numeration')
            mt(ol['title'], "#{ol_path}/head")

            ol['items'].each_with_index do |item, j|
              mt(item, "#{ol_path}/item[#{j+1}]")
            end

          end
        end
      end


      it "maps subnotes[].note_definedlist to NOTE_PATH/list[@listtype='deflist']" do
        multis.each do |note|
          definedlists = get_subnotes_by_type(note, 'note_definedlist')
          next if definedlists.empty?

          ppath = build_path.call(note)

          definedlists.each_with_index do |dl, i|
            dl_path = "#{ppath}/list[@listtype='deflist'][#{i+1}]"

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
        path = "//bioghist[@id = 'aspace_#{@another_note_tracer['persistent_id']}']/chronlist/chronitem/chronitemset/event"

        # we are really testing that the raw XML doesn't container '&amp;amp;'
        mt("LIFE & DEATH", path)
      end

    end



    it "maps {archival_object}.level to {desc_path}@level" do
      mt(object.level, desc_path, "level")
    end


    it "maps {archival_object}.other_level to {desc_path}@otherlevel" do
      mt(object.other_level, desc_path, "otherlevel")
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
            path = "#{desc_path}/controlaccess/#{node_name}/part[contains(text(), '#{agent.names[0]['sort_name']}')]"
            doc.should_not have_node(path)
          end

          next unless %w(source subject).include?(link_role)
          relator = link[:relator] || link['relator']
          role = relator ? relator : (link_role == 'source' ? 'fmo' : nil)
          sort_name = agent.names[0]['sort_name']
          rules = agent.names[0]['rules']
          source = agent.names[0]['source']
          identifier = agent.names[0]['authority_id']
          content = "#{sort_name}"

          terms = link[:terms] || link['terms']

          if terms.length > 0
            content << " -- "
            content << terms.map{|t| t['term']}.join(' -- ')
          end

          path = "#{desc_path}/controlaccess/#{node_name}[./part[contains(text(), '#{sort_name}')]]"
          part_path = "#{desc_path}/controlaccess/#{node_name}/part[contains(text(), '#{sort_name}')]"

          mt(rules, path, 'rules')
          mt(source, path, 'source')
          mt(role, path, 'label')
          mt(identifier, path, 'identifier')
          mt(content.strip, part_path)
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

          path = "#{desc_path}/did/origination/#{node_name}/part[contains(text(), '#{agent.names[0]['sort_name']}')]"

          doc.should have_node(path)
        end
      end


      it "maps linked subjects to {desc_path}/controlaccess/NODE" do
        object.subjects.each do |link|
          ref = link[:ref] || link['ref']
          subject = @subjects[ref]

          node_name = node_name_for_term_type(subject.terms[0]['term_type'])
          next unless node_name

          term_string = subject.terms.map{|t| t['term']}.join(' -- ')

          path = "/ead/archdesc/controlaccess/#{node_name}[./part[text() = '#{term_string}']]"
          part_path = "/ead/archdesc/controlaccess/#{node_name}/part[text() = '#{term_string}']"

          mt(term_string, part_path)
          mt(subject.source, path, 'source')
          mt(subject.authority_id, path, 'identifier')
        end
      end
    end

  end # end shared examples for resources & archival_objects




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
        mt(relator, path_2, 'role')
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
            path = "/ead/archdesc/dao[@href='#{href}']"

            content = description_content(obj)

            xlink_actuate_attribute = fv['xlink_actuate_attribute'].downcase || 'onrequest'
            mt(xlink_actuate_attribute, path, 'actuate')

            xlink_show_attribute = fv['xlink_show_attribute'].downcase || 'new'
            mt(xlink_show_attribute, path, 'show')

            if obj.digital_object_type
              mt('otherdaotype', path, 'daotype')
              mt(obj.digital_object_type, path, 'otherdaotype')
            else
              mt('unknown', path, 'daotype')
            end

            if fv['use_statement']
              mt(fv['use_statement'], path, 'localtype')
            end

            mt(obj.title, path, 'linktitle')
            mt(content, "#{path}/descriptivenote/p")
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
        doc.should have_node(path)
      end



      it_behaves_like "archival object desc mappings" do
        let(:object) { archival_object }
        let(:desc_path) { path }
        let(:desc_nspath) { nspath }
        let(:unitid_src) { object.component_id }
      end

      # describe "How {archival_object}.instances[].digital_object data is mapped." do
      #   let(:instances) { archival_object.instances.reject {|i| i['digital_object'].nil? } }

      #   def description_content(obj)
      #     date = obj['dates'].nil? ? {} : obj['dates'][0]
      #     content = ""
      #     content << "#{obj['title']}" if obj['title']
      #     unless date.nil?
      #       content << ": " if date['expression'] || date['begin']
      #       if date['expression']
      #         content << "#{date['expression']}"
      #       elsif date['begin']
      #         content << "#{date['begin']}"
      #         if date['end'] != date['begin']
      #           content << "-#{date['end']}"
      #         end
      #       end
      #     end
      #     content
      #   end
      # end

    end
  end




  describe "Testing EAD Serializer mixed content behavior" do

    let(:note_with_p) { "<p>A NOTE!</p>" }
    let(:note_with_linebreaks) { "Something, something,\n\nsomething." }
    let(:note_with_linebreaks_and_good_mixed_content) { "Something, something,\n\n<blockquote>something.</blockquote>\n\n" }
    let(:note_with_linebreaks_and_evil_mixed_content) { "Something, something,\n\n<bioghist>something.\n\n</bioghist>\n\n" }
    let(:note_with_linebreaks_but_something_xml_nazis_hate) { "Something, something,\n\n<prefercite>XML & How to Live it!</prefercite>\n\n" }
    let(:note_with_linebreaks_and_xml_namespaces) { "Something, something,\n\n<prefercite xlink:foo='one' ns2:bar='two' >XML, you so crazy!</prefercite>\n\n" }
    let(:note_with_smart_quotes) {"This note has “smart quotes” and ‘smart apostrophes’ from MSWord."}
    let(:note_with_extref) {"Blah blah <extref>blah</extref>"}
    let(:note_with_ref) {"Blah blah <ref>blah</ref>"}
    let(:note_with_namespaced_attributes) { "Blah <ref xlink:href=\"boo\">blah</ref> <ref ns2:foo=\"goo\">blah</ref>." }
    let(:note_with_unnamespaced_attributes) { "Blah <ref href=\"boo\">blah</ref> <ref foo=\"goo\">blah</ref>." }
    let(:serializer) { EAD3Serializer.new }
    let(:note_with_type_attributes) { "Blah <name type=\"blah\">blah</name> blah <date type=\"blah\">1999</date>." }
    let(:note_with_localtype_attributes) { "Blah <name localtype=\"blah\"><part>blah</part></name> blah <date localtype=\"blah\">1999</date>." }
    let(:note_with_access_elements_with_text_children) { "Blah <name>blah</name> blah <title>bloh</title> blah <subject>bluh</subject>." }
    let(:note_with_access_elements_with_part_children) { "Blah <name><part>blah</part></name> blah <title><part>bloh</part></title> blah <subject><part>bluh</part></subject>." }
    let(:note_with_elements_with_mixed_case_attributes) { "Blah <ref actuate=\"onLoad\">blah</ref> blah <date approximate=\"TRUE\">1999</date>." }
    let(:note_with_elements_without_mixed_case_attributes) { "Blah <ref actuate=\"onload\">blah</ref> blah <date approximate=\"true\">1999</date>." }
    let(:note_with_invalid_children_of_p) { "<p>Blah <foo>bluh</foo> blah <emph>bloh</emph> <date>blah <emph>blah</emph> <foo>blah</foo></date></p>" }
    let(:note_without_invalid_children_of_p) { "<p>Blah bluh blah <emph>bloh</emph> <date>blah <emph>blah</emph> blah</date></p>" }
    let(:note_with_ordered_list_2002) { "<list type=\"ordered\" numeration=\"arabic\"><item>foo</item></list>" }
    let(:note_with_ordered_list_ead3) { "<list listtype=\"ordered\" numeration=\"decimal\"><item>foo</item></list>" }

    it "can strip <p> tags from content when disallowed" do
      serializer.strip_p(note_with_p).should eq("A NOTE!")
    end

    it "can leave <p> tags in content" do
      serializer.structure_children(note_with_p).should eq(note_with_p)
    end

    it "will add <p> tags to content with linebreaks" do
      serializer.structure_children(note_with_linebreaks).should eq("<p>Something, something,</p><p>something.</p>")
    end


    it "will add <p> tags to content with linebreaks and mixed content, leaving elements alone that are valid children of passed parent element" do
      serializer.structure_children(note_with_linebreaks_and_good_mixed_content, 'accessrestrict').should eq("<p>Something, something,</p><blockquote>something.</blockquote>")
    end


    it "will leave valid element children as is and wrap invalid children and cdata in <p>" do
      note_in = "<head>blah</head>\n\n blah blah \n\n <p>blah</p><blockquote>blah</blockquote>\n\nblah"
      note_out = "<head>blah</head><p>blah blah</p><p>blah</p><blockquote>blah</blockquote><p>blah</p>"
      serializer.structure_children(note_in, 'scopecontent').should eq(note_out)
    end


    it "will return original content when linebreaks and mixed content produce invalid markup" do
      serializer.structure_children(note_with_linebreaks_and_evil_mixed_content).should eq(note_with_linebreaks_and_evil_mixed_content)
    end

    it "will add <p> tags to content with linebreaks and mixed content even if those evil &'s are present in the text" do
      serializer.structure_children(note_with_linebreaks_but_something_xml_nazis_hate).should eq("<p>Something, something,</p><p><prefercite>XML &amp; How to Live it!</prefercite></p>")
    end

    it "will add <p> tags to content with linebreaks and mixed content even there are weird namespace prefixes" do
      serializer.structure_children(note_with_linebreaks_and_xml_namespaces).should eq("<p>Something, something,</p><p><prefercite xlink:foo='one' ns2:bar='two' >XML, you so crazy!</prefercite></p>")
    end

    it "will replace MSWord-style smart quotes with ASCII characters" do
      serializer.remove_smart_quotes(note_with_smart_quotes).should eq("This note has \"smart quotes\" and \'smart apostrophes\' from MSWord.")
    end

    it "will replace <extref> with <ref>" do
      serializer.convert_ead2002_markup(note_with_extref).should eq(note_with_ref)
    end

    it "will converts list attributes" do
      serializer.convert_ead2002_markup(note_with_ordered_list_2002).should eq(note_with_ordered_list_ead3)
    end

    it "removes namespace prefixes from attributes" do
      serializer.convert_ead2002_markup(note_with_namespaced_attributes).should eq(note_with_unnamespaced_attributes)
    end

    it "converts @type to @localtype when appropriate" do
      serializer.convert_ead2002_markup(note_with_type_attributes).should eq(note_with_localtype_attributes)
    end

    it "wraps text children of access elements in <part>" do
      serializer.convert_ead2002_markup(note_with_access_elements_with_text_children).should eq(note_with_access_elements_with_part_children)
    end

    it "downcases values of all attributes with closed lists" do
      serializer.convert_ead2002_markup(note_with_elements_with_mixed_case_attributes).should eq(note_with_elements_without_mixed_case_attributes)
    end

    it "strips invalid children of p" do
      invalid = note_with_invalid_children_of_p
      valid = note_without_invalid_children_of_p
      serializer.convert_ead2002_markup( invalid ).should eq( valid )
    end

    it "can identify content that includes unwrapped text" do
      enclosed_content = "<blockquote>blah blah blah</blockquote>"
      wrapped_content = "<head>blah</head>\n <p>blah</p>\n <blockquote>blah</blockquote>"
      mixed_content = "blah blah <subject>blah</subject>"
      serializer.has_unwrapped_text?(enclosed_content).should be_falsey
      serializer.has_unwrapped_text?(wrapped_content).should be_falsey
      serializer.has_unwrapped_text?(mixed_content).should be_truthy
    end



  end


  describe "Test unpublished record EAD exports" do

    def get_xml_doc(include_unpublished = false)
      as_test_user("admin") do
        DB.open(true) do
          doc_for_unpublished_resource = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@unpublished_resource_jsonmodel.id}.xml?include_unpublished=#{include_unpublished}&include_daos=true", true)

          doc_nsless_for_unpublished_resource = Nokogiri::XML::Document.parse(doc_for_unpublished_resource)
          doc_nsless_for_unpublished_resource.remove_namespaces!

          return doc_nsless_for_unpublished_resource
        end
      end
    end

    before(:all) {
      RSpec::Mocks.with_temporary_scope do
        # EAD export normally tries the search index first, but for the tests we'll
        # skip that since Solr isn't running.
        allow(Search).to receive(:records_for_uris) do |*|
          {'results' => []}
        end

        unpublished_resource = create(:json_resource,
                                      :publish => false)

        @unpublished_resource_jsonmodel = JSONModel(:resource).find(unpublished_resource.id)

        @published_archival_object = create(:json_archival_object_normal,
                                            :resource => {:ref => @unpublished_resource_jsonmodel.uri},
                                            :publish => true)

        @unpublished_archival_object = create(:json_archival_object_normal,
                                              :resource => {:ref => @unpublished_resource_jsonmodel.uri},
                                              :publish => false)

        @xml_including_unpublished = get_xml_doc(include_unpublished = true)
        @xml_not_including_unpublished = get_xml_doc(include_unpublished = false)
      end
    }

    it "does not set <ead> attribute audience 'internal' when resource is published" do
      @doc_nsless.at_xpath('//ead').should_not have_attribute('audience', 'internal')
    end

    it "sets <ead> attribute audience 'internal' when resource is not published" do
      @xml_including_unpublished.at_xpath('//ead').should have_attribute('audience', 'internal')
      @xml_not_including_unpublished.at_xpath('//ead').should have_attribute('audience', 'internal')
    end

    it "includes unpublished items when include_unpublished option is false" do
      @xml_including_unpublished.xpath('//c').length.should eq(2)
      @xml_including_unpublished.xpath("//c[@id='aspace_#{@published_archival_object.ref_id}'][not(@audience='internal')]").length.should eq(1)
      @xml_including_unpublished.xpath("//c[@id='aspace_#{@unpublished_archival_object.ref_id}'][@audience='internal']").length.should eq(1)
    end

    it "does not include unpublished items when include_unpublished option is false" do
      items = @xml_not_including_unpublished.xpath('//c')
      items.length.should eq(1)

      item = items.first
      item.should_not have_attribute('audience', 'internal')
    end
  end



  describe "Test suppressed record EAD exports" do

    def get_xml_doc
      as_test_user("admin") do
        DB.open(true) do
          doc_for_resource = get_xml("/repositories/#{$repo_id}/resource_descriptions/#{@resource_jsonmodel.id}.xml?include_unpublished=true&include_daos=true", true)

          doc_nsless_for_resource = Nokogiri::XML::Document.parse(doc_for_resource)
          doc_nsless_for_resource.remove_namespaces!

          return doc_nsless_for_resource
        end
      end
    end


    before(:all) {
      RSpec::Mocks.with_temporary_scope do
        # EAD export normally tries the search index first, but for the tests we'll
        # skip that since Solr isn't running.
        allow(Search).to receive(:records_for_uris) do |*|
          {'results' => []}
        end

        resource = create(:json_resource,
                          :publish => false)

        @resource_jsonmodel = JSONModel(:resource).find(resource.id)

        @suppressed_series = create(:json_archival_object_normal,
                                    :resource => {:ref => @resource_jsonmodel.uri},
                                    :publish => true,
                                    :suppressed => true)

        @unsuppressed_series = create(:json_archival_object_normal,
                                      :resource => {:ref => @resource_jsonmodel.uri},
                                      :publish => true,
                                      :suppressed => false)

        @suppressed_series_unsuppressedchild = create(:json_archival_object_normal,
                                                      :resource => {:ref => @resource_jsonmodel.uri},
                                                      :parent => {:ref => @suppressed_series.uri},
                                                      :publish => true,
                                                      :suppressed => false)

        @unsuppressed_series_unsuppressed_child = create(:json_archival_object_normal,
                                                         :resource => {:ref => @resource_jsonmodel.uri},
                                                         :parent => {:ref => @unsuppressed_series.uri},
                                                         :publish => true,
                                                         :suppressed => false)

        @unsuppressed_series_suppressed_child = create(:json_archival_object_normal,
                                                       :resource => {:ref => @resource_jsonmodel.uri},
                                                       :parent => {:ref => @unsuppressed_series.uri},
                                                       :publish => true,
                                                       :suppressed => true)

        @xml = get_xml_doc
      end
    }

    it "excludes suppressed items" do
      @xml.xpath('//c').length.should eq(2)
      @xml.xpath("//c[@id='aspace_#{@unsuppressed_series.ref_id}']").length.should eq(1)
      @xml.xpath("//c[@id='aspace_#{@unsuppressed_series_unsuppressed_child.ref_id}']").length.should eq(1)
    end
  end



end
