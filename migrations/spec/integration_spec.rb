require_relative "spec_helper.rb"

def get_note(obj, id)
  obj['notes'].find{|n| n['persistent_id'] == id}
end

def get_notes_by_type(obj, note_type)
  obj['notes'].select{|n| n['type'] == note_type}
end

def get_note_by_type(obj, note_type)
  get_notes_by_type(obj, note_type)[0]
end


def get_subnotes_by_type(obj, note_type)
  obj['subnotes'].select {|sn| sn['jsonmodel_type'] == note_type}
end

def note_content(note)
  if note['content']
    Array(note['content']).join("")
  else
    get_subnotes_by_type(note, 'note_text').map {|sn| sn['content']}.join("").gsub(/\n +/, "\n")
  end
end

def get_notes_by_string(notes, string)
  notes.select {|note| (note.has_key?('subnotes') && note['subnotes'][0]['content'] == string) \
                    || (note['content'].is_a?(Array) && note['content'][0] == string) }
end

def get_family_by_name(families, famname)
  families.find {|f| f['names'][0]['family_name'] == famname}
end

def get_person_by_name(people, primary_name)
  people.find {|p| p['names'][0]['primary_name'] == primary_name}
end

def get_corp_by_name(corps, primary_name)
  corps.find {|c| c['names'][0]['primary_name'] == primary_name}
end

describe 'ASpaceImport' do

  before(:all) do
    start_backend
    @vocab_uri = make_test_vocab
  end

  before(:each) do
    @repo = create(:json_repo)
    @repo_id = @repo.class.id_for(@repo.uri)

    @opts = {
      :repo_id => @repo_id,
      :vocab_uri => build(:json_vocab).class.uri_for(2)
    }
  end

  after(:each) do
    @opts = {}
  end

  after(:all) do
    stop_backend
  end


  it "can import the file at examples/ead/ferris.xml" do

    @opts.merge!({
            :input_file => '../examples/ead/ferris.xml',
            :importer => 'ead',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)

    count = 0

    @i.run_safe do |msg|
      if msg['saved']
        count = msg['saved'].count
      end
    end

    (count > 0).should be(true)
  end


  it "can import the file at examples/eac/feynman-richard-phillips-1918-1988-cr.xml" do
    @opts.merge!({
            :input_file => '../examples/eac/feynman-richard-phillips-1918-1988-cr.xml',
            :importer => 'eac',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)

    count = 0

    @i.run_safe do |msg|
      if msg['saved']
        count = msg['saved'].count
      end
    end

    (count > 0).should be(true)
  end


  it "can import the file at examples/marc/american-communist.xml" do
    @opts.merge!({
            :input_file => '../examples/marc/american-communist.xml',
            :importer => 'marcxml',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)

    count = 0

    @i.run_safe do |msg|
      if msg['saved']
        count = msg['saved'].count
      end
    end

    (count > 0).should be(true)
  end


  it "can import the file at examples/csv/do_tracer_v2.csv" do
    @opts.merge!({
            :input_file => '../examples/csv/do_tracer_v2.csv',
            :importer => 'digital_objects',
            :quiet => true
            })

    @i = ASpaceImport::Importer.create_importer(@opts)

    count = 0

    @i.run_safe do |msg|
      if msg['saved']
        count = msg['saved'].count
      end
    end

    count.should eq(18)
  end


  describe "EAD Import Mappings" do

    before(:all) do

      @repo = create(:json_repo)
      @repo_id = @repo.class.id_for(@repo.uri)

      opts = {
        :repo_id => @repo_id,
        :vocab_uri => build(:json_vocab).class.uri_for(2),
        :input_file => '../examples/ead/at-tracer.xml',
        :importer => 'ead',
        :quiet => true
      }

      @i = ASpaceImport::Importer.create_importer(opts)

      @count = 0
      @saved = {}

      @i.run_safe do |msg|
        if msg['saved']
          @count = msg['saved'].count
          @saved = msg['saved']
        end
      end

      @corps = []
      @saved.keys.select {|k| k =~ /\/corporate_entities\//}.each do |k|
        @corps << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @families = []
      @saved.keys.select {|k| k =~ /\/families\//}.each do |k|
        @families << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @people = []
      @saved.keys.select {|k| k =~ /\/people\//}.each do |k|
        @people << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @subjects = []
      @saved.keys.select {|k| k =~ /\/subjects\//}.each do |k|
        @subjects << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @digital_objects = []
      @saved.keys.select {|k| k =~ /\/digital_objects\//}.each do |k|
        @digital_objects << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @archival_objects = {}
      @saved.keys.select {|k| k =~ /\/archival_objects\//}.each do |k|
        a = JSONModel::HTTP.get_json(@saved[k][0])
        a['title'].match(/C([0-9]{2})/) do |m|
          @archival_objects[m[1]] = a
        end
      end

      @resource = JSONModel::HTTP.get_json(@saved.values.last[0])
    end

    it "can import the tracer EAD at /examples/ead/at-tracer.xml" do
      (@count > 0).should be(true)
    end

    it "creates the archival object tree correctly" do
      # check the hierarchy (don't be fooled by the system ids when this test fails - they won't match the keys)
      @archival_objects.each do |k, v|
        if k.to_i > 1
          parent_key = sprintf '%02d', k.to_i - 1
          v['parent']['ref'].should eq(@archival_objects[parent_key]['uri'])
        end
      end
    end


    # SPECIFICATION SOURCE: https://archivesspace.basecamphq.com/F158503515
    # Comments should roughly match column 1 of the spreadsheet

    # Note: Elements should be linked at the appropriate level (e.g. in the context to a Resource or Archival Object record).

    # Source element	Processing / Formatting Directions
    #  @id
    #  @target
    #  @audience	WHEN @audience = internal

    # RESOURCE
    it "maps '<date>' correctly" do
    # 	IF nested in <chronitem>
      get_subnotes_by_type(get_note(@archival_objects['12'], 'ref53'), 'note_chronology')[0]['items'][0]['event_date'].should eq('1895')

      get_subnotes_by_type(get_note(@archival_objects['12'], 'ref53'), 'note_chronology')[0]['items'][1]['event_date'].should eq('1995')

    # 	IF nested in <publicationstmt>
      @resource['finding_aid_date'].should eq('Resource-FindingAidDate-AT')

    # 	ELSE
    end

    it "maps '<extent>' correctly" do
    #  	IF value starts with a number followed by a space and can be parsed
      @resource['extents'][0]['number'].should eq("5.0")
      @resource['extents'][0]['extent_type'].should eq("Linear feet")

    # 	ELSE
      @resource['extents'][0]['container_summary'].should eq("Resource-ContainerSummary-AT")
    end


    it "maps '<unitdate>' correctly" do
      @resource['dates'][0]['expression'].should eq("Bulk, 1960-1970")
      @resource['dates'][0]['date_type'].should eq("bulk")

      @resource['dates'][1]['expression'].should eq("Resource-Title-AT")
      @resource['dates'][1]['date_type'].should eq("inclusive")
    end

    it "maps '<unitid>' correctly" do
    # 	IF nested in <archdesc><did>
      @resource["id_0"].should eq("Resource.ID.AT")

    # 	IF nested in <c><did>
    end

    it "maps '<unittitle>' correctly" do
    # 	IF nested in <archdesc><did>
      @resource["title"].should eq("Resource--Title-AT")
    # 	IF nested in <c><did>
      @archival_objects['12']['title'].should eq("Resource-C12-AT")
    end


    # FINDING AID ELEMENTS
    it "maps '<author>' correctly" do
      @resource['finding_aid_author'].should eq('Finding aid prepared by Resource-FindingAidAuthor-AT')
    end

    it "maps '<descrules>' correctly" do
      @resource['finding_aid_description_rules'].should eq('Describing Archives: A Content Standard')
    end

    it "maps '<eadid>' correctly" do
      @resource['ead_id'].should eq('Resource-EAD-ID-AT')
    end

    it "maps '<eadid @url>' correctly" do
      @resource['ead_location'].should eq('Resource-EAD-Location-AT')
    end

    it "maps '<editionstmt>' correctly" do
      @resource['finding_aid_edition_statement'].should eq("<p>Resource-FindingAidEdition-AT</p>")
    end

    it "maps '<seriesstmt>' correctly" do
      @resource['finding_aid_series_statement'].should eq("<p>Resource-FindingAidSeries-AT</p>")
    end

    it "maps '<sponsor>' correctly" do
      @resource['finding_aid_sponsor'].should eq('Resource-Sponsor-AT')
    end

    it "maps '<subtitle>' correctly" do
    end

    it "maps '<titleproper>' correctly" do
      @resource['finding_aid_title'].should eq("Resource-FindingAidTitle-AT\n<num>Resource.ID.AT</num>")
    end

    it "maps '<titleproper type=\"filing\">' correctly" do
      @resource['finding_aid_filing_title'].should eq('Resource-FindingAidFilingTitle-AT')
    end

    it "maps '<langusage>' correctly" do
      @resource['finding_aid_language'].should eq('Resource-FindingAidLanguage-AT')
    end

    it "maps '<revisiondesc>' correctly" do
      @resource['finding_aid_revision_description'].should eq("<change>\n<date>Resource-FindingAidRevisionDate-AT</date>\n<item>Resource-FindingAidRevisionDescription-AT</item>\n</change>")
    end

    # NAMES
    it "maps '<corpname>' correctly" do
    # 	IF nested in <origination> OR <controlaccess>
    # 	IF nested in <origination>
      c1 = @corps.find {|corp| corp['names'][0]['primary_name'] == "CNames-PrimaryName-AT. CNames-Subordinate1-AT. CNames-Subordiate2-AT. (CNames-Number-AT) (CNames-Qualifier-AT)"}
      c1.should_not be_nil

      linked = @resource['linked_agents'].find {|a| a['ref'] == c1['uri']}
      linked['role'].should eq('creator')
    # 	IF nested in <controlaccess>
      c2 = @corps.find {|corp| corp['names'][0]['primary_name'] == "CNames-PrimaryName-AT. CNames-Subordinate1-AT. CNames-Subordiate2-AT. (CNames-Number-AT) (CNames-Qualifier-AT) -- Archives"}
      c2.should_not be_nil

      linked = @resource['linked_agents'].find {|a| a['ref'] == c2['uri']}
      linked['role'].should eq('subject')

    # 	ELSE
    # 	IF @rules != NULL ==> name_corporate_entity.rules
      [c1, c2].map {|c| c['names'][0]['rules']}.uniq.should eq(['dacs'])
    # 	IF @source != NULL ==> name_corporate_entity.source
      [c1, c2].map {|c| c['names'][0]['source']}.uniq.should eq(['naf'])
    # 	IF @authfilenumber != NULL
    end

    it "maps '<famname>' correctly" do
    # 	IF nested in <origination> OR <controlaccess>
      uris = @archival_objects['06']['linked_agents'].map {|l| l['ref'] } & @families.map {|f| f['uri'] }
      links = @archival_objects['06']['linked_agents'].select {|l| uris.include?(l['ref']) }
      fams = @families.select {|f| uris.include?(f['uri']) }

    # 	IF nested in <origination>
      n1 = fams.find{|f| f['uri'] == links.find{|l| l['role'] == 'creator' }['ref'] }['names'][0]['family_name']
      n1.should eq("FNames-FamilyName-AT, FNames-Prefix-AT, FNames-Qualifier-AT")
    # 	IF nested in <controlaccess>
      n2 = fams.find{|f| f['uri'] == links.find{|l| l['role'] == 'subject' }['ref'] }['names'][0]['family_name']
      n2.should eq("FNames-FamilyName-AT, FNames-Prefix-AT, FNames-Qualifier-AT -- Pictorial works")
    # 	ELSE
    # 	IF @rules != NULL
      fams.map{|f| f['names'][0]['rules']}.uniq.should eq(['aacr'])
    # 	IF @source != NULL
      fams.map{|f| f['names'][0]['source']}.uniq.should eq(['naf'])
    # 	IF @authfilenumber != NULL
    end

    it "maps '<persname>' correctly" do
    # 	IF nested in <origination> OR <controlaccess>
    # 	IF nested in <origination>
      @archival_objects['01']['linked_agents'].find {|l| @people.map{|p| p['uri'] }.include?(l['ref'])}['role'].should eq('creator')
    # 	IF nested in <controlaccess>
      @archival_objects['06']['linked_agents'].reverse.find {|l| @people.map{|p| p['uri'] }.include?(l['ref'])}['role'].should eq('subject')
    # 	ELSE
    # 	IF @rules != NULL
      @people.map {|p| p['names'][0]['rules']}.uniq.should eq(['local'])
    # 	IF @source != NULL
      @people.map {|p| p['names'][0]['source']}.uniq.should eq(['local'])
    # 	IF @authfilenumber != NULL
    end

    # SUBJECTS
    it "maps '<function>' correctly" do
    # 	IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'function'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
    #   @source
    	subject['source'].should eq('local')
    # 	ELSE
    # 	IF @authfilenumber != NULL
    end

    it "maps '<genreform>' correctly" do
    # 	IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'genre_form'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
    #   @source
    	subject['source'].should eq('local')
    # 	ELSE
    # 	IF @authfilenumber != NULL
    end

    it "maps '<geogname>' correctly" do
    # 	IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'geographic'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
    #   @source
    	subject['source'].should eq('local')
    # 	ELSE
    # 	IF @authfilenumber != NULL
    end

    it "maps '<occupation>' correctly" do
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'occupation'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
    #   @source
    	subject['source'].should eq('local')
    # 	ELSE
    # 	IF @authfilenumber != NULL
    end

    it "maps '<subject>' correctly" do
    # 	IF nested in <controlaccess>
      subject = @subjects.find{|s| s['terms'][0]['term_type'] == 'topical'}
      [@resource, @archival_objects["06"], @archival_objects["12"]].each do |a|
        a['subjects'].select{|s| s['ref'] == subject['uri']}.count.should eq(1)
      end
    #   @source
    	subject['source'].should eq('local')
    # 	ELSE
    # 	IF @authfilenumber != NULL
    end

    # NOTES
    # if other EAD elements that map to a note object are nested in eachother, then those notes will be treated as separate notes;
    # for example, a <scopecontent> may contain another <scopecontent>, etc.;
    # therefore, if  <scopecontent> tag contains a nested <scopecontent>, the note contents will be mapped into two separate notes of type "Scope and Contents note" in the Toolkit;
    # if, for example, an <accessrestrict> tag contains a nested <legalstatus>, the tag contents will be mapped into separate notes, one of type "accessrestict" and the part tagged as <legalstatus> as type "legalstatus".
    # if one or more <note> tags are nested, then those <note> tags will initiate separate notes with the NoteType equivalent to the parent note.
    # That is, where <accessrestrict> tag contains a nested <note>, the tag contents will be mapped  into two separate notes of type "Access Restrictions" in the Toolkit.

    # @id	ALL @id attributes on note tags map to the persistent_id property

    # Simple Notes
    it "maps '<abstract>' correctly" do
      note_content(get_note_by_type(@resource, 'abstract')).should eq("Resource-Abstract-AT")
    end

    it "maps '<accessrestrict>' correctly" do
      nc = get_notes_by_type(@resource, 'accessrestrict').map {|note|
        note_content(note)
      }.flatten

      nc[0].should eq("<head>Resource-ConditionsGoverningAccess-AT</head>\n<p>Resource-ConditionsGoverningAccess-AT</p>")
      nc[1].should eq("<head>Resource-LegalStatus-AT</head>\n<legalstatus>Resource-LegalStatus-AT</legalstatus>")
    end

    it "maps '<accruals>' correctly" do
      note_content(get_note_by_type(@resource, 'accruals')).should eq("<head>Resource-Accruals-AT</head>\n<p>Resource-Accruals-AT</p>")
    end

    it "maps '<acqinfo>' correctly" do
      note_content(get_note_by_type(@resource, 'acqinfo')).should eq("<head>Resource-ImmediateSourceAcquisition</head>\n<p>Resource-ImmediateSourceAcquisition</p>")
    end

    it "maps '<altformavail>' correctly" do
      note_content(get_note_by_type(@resource, 'altformavail')).should eq("<head>Resource-ExistenceLocationCopies-AT</head>\n<p>Resource-ExistenceLocationCopies-AT</p>")
    end

    it "maps '<appraisal>' correctly" do
      note_content(get_note_by_type(@resource, 'appraisal')).should eq("<head>Resource-Appraisal-AT</head>\n<p>Resource-Appraisal-AT</p>")
    end

    it "maps '<arrangement>' correctly" do
      note_content(get_note_by_type(@resource, 'arrangement')).should eq("<head>Resource-Arrangement-Note</head>\n<p>Resource-Arrangement-Note</p>")
    end

    it "maps '<bioghist>' correctly" do
      @archival_objects['06']['notes'].find{|n| n['type'] == 'bioghist'}['persistent_id'].should eq('ref50')
      @archival_objects['12']['notes'].find{|n| n['type'] == 'bioghist'}['persistent_id'].should eq('ref53')
      @resource['notes'].select{|n| n['type'] == 'bioghist'}.map{|n| n['persistent_id']}.sort.should eq(['ref47', 'ref7'])
    end

    it "maps '<custodhist>' correctly" do
      note_content(get_note_by_type(@resource, 'custodhist')).should eq("<head>Resource--CustodialHistory-AT</head>\n<p>Resource--CustodialHistory-AT</p>")
    end

    it "maps '<dimensions>' correctly" do
      note_content(get_note_by_type(@resource, 'dimensions')).should eq("Resource-Dimensions-AT")
    end

    it "maps '<fileplan>' correctly" do
      note_content(get_note_by_type(@resource, 'fileplan')).should eq("<head>Resource-FilePlan-AT</head>\n<p>Resource-FilePlan-AT</p>")
    end

    it "maps '<langmaterial>' correctly" do
      note_content(get_note_by_type(@archival_objects['06'], 'langmaterial')).should eq("<language langcode=\"eng\"/>")
    end

    it "maps '<legalstatus>' correctly" do
      note_content(get_note_by_type(@resource, 'legalstatus')).should eq("Resource-LegalStatus-AT")
    end

    it "maps '<materialspec>' correctly" do
      get_note_by_type(@resource, 'materialspec')['persistent_id'].should eq("ref22")
    end

    it "maps '<note>' correctly" do
    # 	IF nested in <archdesc> OR <c>

    # 	ELSE, IF nested in <notestmnt>
      @resource['finding_aid_note'].should eq("<p>Resource-FindingAidNote-AT</p>")
    # 	ELSE
    end

    it "maps '<odd>' correctly" do
      @resource['notes'].select{|n| n['type'] == 'odd'}.map{|n| n['persistent_id']}.sort.should eq(%w(ref45 ref44 ref15).sort)
    end

    it "maps '<originalsloc>' correctly" do
      get_note_by_type(@resource, 'originalsloc')['persistent_id'].should eq("ref13")
    end

    it "maps '<otherfindaid>' correctly" do
      get_note_by_type(@resource, 'otherfindaid')['persistent_id'].should eq("ref23")
    end

    it "maps '<physdesc>' correctly" do
      @resource['notes'].find{|n| n['persistent_id'] == 'ref25'}['type'].should eq('physdesc')
      @archival_objects['02']['notes'].find{|n| n['type'] == 'physdesc'}['content'][0].should eq("<extent>1.0 Linear feet</extent>\n<extent>Resource-C02-ContainerSummary-AT</extent>")
    end

    it "maps '<physfacet>' correctly" do
      note_content(get_note_by_type(@resource, 'physfacet')).should eq("Resource-PhysicalFacet-AT")
    end

    it "maps '<physloc>' correctly" do
      get_note_by_type(@resource, 'physloc')['persistent_id'].should eq("ref21")
    end

    it "maps '<phystech>' correctly" do
      get_note_by_type(@resource, 'phystech')['persistent_id'].should eq("ref24")
    end

    it "maps '<prefercite>' correctly" do
      get_note_by_type(@resource, 'prefercite')['persistent_id'].should eq("ref26")
    end

    it "maps '<processinfo>' correctly" do
      get_note_by_type(@resource, 'prefercite')['persistent_id'].should eq("ref26")
    end

    it "maps '<relatedmaterial>' correctly" do
      get_note_by_type(@resource, 'prefercite')['persistent_id'].should eq("ref26")
    end

    it "maps '<scopecontent>' correctly" do
      get_note_by_type(@resource, 'scopecontent')['persistent_id'].should eq("ref29")
      @archival_objects['01']['notes'].find{|n| n['type'] == 'scopecontent'}['persistent_id'].should eq("ref43")
    end

    it "maps '<separatedmaterial>' correctly" do
      get_note_by_type(@resource, 'separatedmaterial')['persistent_id'].should eq("ref30")
    end

    it "maps '<userestrict>' correctly" do
      get_note_by_type(@resource, 'userestrict')['persistent_id'].should eq("ref9")
    end

    # Structured Notes
    it "maps '<bibliography>' correctly" do
    #   	IF nested in <archdesc>  OR <c>
      @resource['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id'].should eq("ref6")
      @archival_objects['06']['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id'].should eq("ref48")
      @archival_objects['12']['notes'].find{|n| n['jsonmodel_type'] == 'note_bibliography'}['persistent_id'].should eq("ref51")
    #     <head>
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['label'].should eq("Resource--C06-Bibliography")
    #     <p>
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['content'][0].should eq("Resource--C06--Bibliography--Head")
    #     <bibref>
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['items'][0].should eq("c06 bibItem2")
      @archival_objects['06']['notes'].find{|n| n['persistent_id'] == 'ref48'}['items'][1].should eq("c06 bibItem1")
    #     other nested and inline elements
    end

    it "maps '<index>' correctly" do
    # 	IF nested in <archdesc>  OR <c>
      ref52 = get_note(@archival_objects['12'], 'ref52')
      ref52['jsonmodel_type'].should eq('note_index')
    #     <head>
      ref52['label'].should eq("Resource-c12-Index")
    #     <p>
      ref52['content'][0].should eq("Resource-c12-index-note")
    #     <indexentry>
    #         <name>

    #         <persname>

    #         <famname>
      ref52['items'].find{|i| i['type'] == 'family'}['value'].should eq('Bike 2')
    #         <corpname>
      ref52['items'].find{|i| i['type'] == 'corporate_entity'}['value'].should eq('Bike 3')
    #         <subject>

    #         <function>

    #         <occupation>

    #         <genreform>
      ref52['items'].find{|i| i['type'] == 'genre_form'}['value'].should eq('Bike 1')
    #         <title>

    #         <geogname>

    #         <ref>
    #     other nested and inline elements
    end


    # Mixed Content Note Parts
    it "maps '<chronlist>' correctly" do
    #     <head>
    #     <chronitem>
    #         <date>
    #         <event>
      ref53 = get_note(@archival_objects['12'], 'ref53')
      get_subnotes_by_type(ref53, 'note_chronology')[0]['items'][0]['events'][0].should eq('first date')
      get_subnotes_by_type(ref53, 'note_chronology')[0]['items'][1]['events'][0].should eq('second date')

    #         <eventgrp><event>
      ref50 = get_subnotes_by_type(get_note(@archival_objects['06'], 'ref50'), 'note_chronology')[0]
      item = ref50['items'].find{|i| i['event_date'] && i['event_date'] == '1895'}
      item['events'].sort.should eq(['Event1', 'Event2'])
    #         other nested and inline elements
    end

    # WHEN @type = deflist OR @type = NULL AND <defitem> present
    it "maps '<list>' correctly" do
      ref47 = get_note(@resource, 'ref47')
      note_dl = ref47['subnotes'].find{|n| n['jsonmodel_type'] == 'note_definedlist'}
    #     <head>
      note_dl['title'].should eq("Resource-BiogHist-structured-top-part3-listDefined")
    #     <defitem>	WHEN <list> @type = deflist
    #         <label>
      note_dl['items'].map {|i| i['label']}.sort.should eq(['MASI SLP', 'Yeti Big Top', 'Intense Spider 29'].sort)
    #         <item>
      note_dl['items'].map {|i| i['value']}.sort.should eq(['2K', '2500 K', '4500 K'].sort)
    # ELSE WHEN @type != deflist AND <defitem> not present
      ref44 = get_note(@resource, 'ref44')
      note_ol = get_subnotes_by_type(ref44, 'note_orderedlist')[0]
    #     <head>
      note_ol['title'].should eq('Resource-GeneralNoteMULTIPARTLISTTitle-AT')
    #     <item>
      note_ol['items'].sort.should eq(['Resource-GeneralNoteMULTIPARTLISTItem1-AT', 'Resource-GeneralNoteMULTIPARTLISTItem2-AT'])
    end

    # CONTAINER INFORMATION
    # Up to three container elements can be imported per <c>.
    # The Asterisks in the target element field below represents the numbers "1", "2", or "3" depending on which <container> tag the data is coming from

    it "maps '<container>' correctly" do
      i = @archival_objects['02']['instances'][0]
      i['instance_type'].should eq('mixed_materials')
      i['container']['indicator_1'].should eq('cid2')
      i['container']['indicator_2'].should be_nil
    #   @type
      i['container']['type_1'].should eq('Box')
      i['container']['type_2'].should eq('Folder')
    end

    # DAO's
    it "maps '<dao>' correctly" do
      @digital_objects.length.should eq(12)
      links = @archival_objects['01']['instances'].select{|i| i.has_key?('digital_object')}.map{|i| i['digital_object']['ref']}
      links.sort.should eq(@digital_objects.map{|d| d['uri']}.sort)
    #   @titles
      @digital_objects.map {|d| d['title']}.include?("DO.Child2Title-AT").should be(true)
    #   @role
      uses = @digital_objects.map {|d| d['file_versions'].map {|f| f['use_statement']}}.flatten
      uses.uniq.sort.should eq(["Image-Service", "Image-Master", "Image-Thumbnail"].sort)
    #   @href
      uris = @digital_objects.map {|d| d['file_versions'].map {|f| f['file_uri']}}.flatten
      (uris.include?('DO.Child1URI2-AT')).should be(true)
    #   @actuate
      @digital_objects.select{|d| d['file_versions'][0]['xlink_actuate_attribute'] == 'onRequest'}.length.should eq(9)
    #   @show
      @digital_objects.select{|d| d['file_versions'][0]['xlink_show_attribute'] == 'new'}.length.should eq(3)
    end

    # FORMAT & STRUCTURE
    it "maps '<archdesc>' correctly" do
    #   @level	IF != NULL
      @resource['level'].should eq("collection")
    # 	ELSE
    #   @otherlevel
    end

    it "maps '<c>' correctly" do
    #   @level	IF != NULL
      @archival_objects['04']['level'].should eq('file')
    # 	ELSE
    #   @otherlevel
    #   @id
      @archival_objects['05']['ref_id'].should eq('ref34')
    end
  end

  describe "MARC import mappings" do

    before(:all) do

      # Since the tracer MARC file contains records that are virtually duplicate
      # it's necessary to keep track of the logical uris / sequence
      module ASpaceImport
        module Utils
          class << self
            alias_method :real_mint_id, :mint_id

            def mint_id
              @count ||= 0
              @count += 1
              @count
            end
          end
        end
      end

      @repo = create(:json_repo)
      @repo_id = @repo.class.id_for(@repo.uri)

      opts = {
        :repo_id => @repo_id,
        :vocab_uri => build(:json_vocab).class.uri_for(2),
        :input_file => '../examples/marc/at-tracer-marc-1.xml',
        :importer => 'marcxml',
        :quiet => true
      }

      @i = ASpaceImport::Importer.create_importer(opts)

      @count = 0
      @saved = {}

      @i.run_safe do |msg|
        if msg['saved']
          @count = msg['saved'].count
          @saved = msg['saved']
        end
      end

      @corps = []
      @saved.keys.select {|k| k =~ /\/corporate_entities\//}.each do |k|
        @corps << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @families = []
      @saved.keys.select {|k| k =~ /\/families\//}.each do |k|
        @families << JSONModel::HTTP.get_json(@saved[k][0])
      end

      @families.instance_eval do
        def by_name(name)
          self.select {|f| f['names'][0]['family_name'] == name}
        end

        def uris_for_name(name)
          by_name(name).map {|f| f['uri']}
        end
      end

      @people = []
      @saved.keys.select {|k| k =~ /\/people\/([0-9]{1,2})/}.each do |k|
        @people << JSONModel::HTTP.get_json(@saved[k][0])
        @people.last['test_id'] = $1.to_i
      end

      @people.instance_eval do
        def by_name(name)
          self.select {|p| p['names'][0]['primary_name'] == name}
        end

        def uris_for_name(name)
          by_name(name).map {|f| f['uri']}
        end

        def by_num(id)
          @people.find {|p| p['test_id'] == id}
        end
      end

      @subjects = []
      @saved.keys.select {|k| k =~ /\/subjects\//}.each do |k|
        @subjects << JSONModel::HTTP.get_json(@saved[k][0])
      end
      resource_logical_uri = @saved.keys.find{|k| k =~ /\/resources\//}
      @resource = JSONModel::HTTP.get_json(@saved[resource_logical_uri][0])
      @notes = @resource['notes']
    end

    after(:all) do
      module ASpaceImport
        module Utils
          class << self
            alias_method :mint_id, :real_mint_id
          end
        end
      end
    end

    it "can import the tracer MARC at /examples/marc/at-tracer-marc-1.xml" do
      (@count > 0).should be(true)
    end

    # Tag ind1  ind2  Subfield code   Object  Property
    # 008
    #         The 008 is a string of values derived from the fixed fields of the MARC record.  Each fixed field value has a zero-indexed absolute position on in the string.
    # Positions 0-5 represent the date the record was created.
    # Position 6 is a single alpha character representing the date type.
    # Positions 7-14 represent the date information (two four digit dates in most cases).
    # Positions 35-37 represent a three-letter language code taken from the MARC Code List for Languages. Three fill characters ('|||' or 3 spaces) may be used if no attempt was made to code the language.
    #
    # For example, given the 008 string:
    # 880812s1967    xxu                 eng d
    #
    # This represents a single date with the year 1967 and a resource in English (code 'eng').
    #
    #       position 6  IF position 6 = 'i', date.date_type is "inclusive"  date  date_type
    #         IF position 6 = 'k', date.date_type is "bulk"
    #         IF position 6 = 's', date.date_type is "single"
    #       positions 7-10    date  begin
    #       positions 11-14   date  end
    #       positions 35-37   resource  language
    # Sample "130109i19601970xx                  eng d"
    it "maps field 008 correctly" do
      @resource['language'].should eq('eng')
      date = @resource['dates'].find {|d| d['date_type'] == 'inclusive' && d['begin'] == '1960' && d['end'] == '1970'}
      date.should_not be_nil
    end

    it "maps datafield[@tag='600'] to agent_family and agent_person linked as 'subject'" do
      links = @resource['linked_agents'].select {|a| @families.uris_for_name('FNames-FamilyName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'subject'}.count.should eq(1)

      links = @resource['linked_agents'].select {|a| @people.uris_for_name('PNames-Primary-AT, PNames-RestOfName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'subject'}.count.should eq(1)
    end

    it "maps datafield[@tag='700'][@ind1='1'][@subfield[@code='e']='Donor (dnr)'] to agent_person linked as 'source'" do
      links = @resource['linked_agents'].select {|a| @people.uris_for_name('PNames-Primary-AT, PNames-RestOfName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'source'}.count.should eq(1)
    end

    it "maps datafield[@tag='700'][@ind1='1'][@subfield[@code='e']] to agent_person linked as 'creator'" do
      links = @resource['linked_agents'].select {|a| @people.uris_for_name('PNames-Primary-AT, PNames-RestOfName-AT').include?(a['ref'])}
      links.select {|l| l['role'] == 'creator'}.count.should eq(1)
    end

    it "maps datafield[@tag='600']/subfield[@code='2'] to agent_(family|person).names[].source" do
      @families.select {|f| f['names'][0]['source'] == 'NACO Authority File'}.count.should eq(1)
    end

    it "maps datafield[@tag='600' or @tag='700']/subfield[@code='b'] to agent_(family|person).names[].number" do
      @people.select{|p| p['names'][0]['number'] == 'PName-Number-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='600' or @tag='700']/subfield[@code='c'] to agent_person.names[].title or agent_family.names[].qualifier" do
      @people.select{|p| p['names'][0]['title'] == 'PNames-Prefix-AT, PNames-Title-AT, PNames-Suffix-AT'}.count.should eq(3)
      @families.select{|f| f['names'][0]['qualifier'].match(/^FNames-Prefix-AT/)}.count.should eq(3)
    end

    it "maps datafield[@tag='600' or @tag='700']/subfield[@code='d'] to agent_(family|person).names[].use_dates[].expression" do
      @people.select{|p| p['names'][0]['use_dates'][0]['expression'] == 'PNames-Dates-AT'}.count.should eq(3)
    end

    it "prepends and maps datafield[@tag='600']/subfield[@code='g'] to agent_(family|person).names[].qualifier" do
      @people.select{|p| p['names'][0]['qualifier'].match(/Miscellaneous information: PNames-Qualifier-AT\./)}.count.should eq(3)
    end

    it "maps datafield[@tag='110' or @tag='610' or @tag='710'] to agent_corporate_entity" do
      @corps.count.should eq(3)
    end

    it "maps datafield[@tag='110' or @tag='610' or @tag='710'] to agent_corporate_entity with source 'ingest'" do
      @corps.select {|f| f['names'][0]['source'] == 'ingest'}.count.should eq(2)
    end

    it "maps datafield[@tag='610']/subfield[@code='2'] to agent_corporate_entity.names[].source" do
      @corps.select {|f| f['names'][0]['source'] == 'NACO Authority File'}.count.should eq(1)
    end

    it "maps datafield[@tag='610'] to agent_corporate_entity linked as 'subject'" do
      links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
      links.select {|l| l['role'] == 'subject'}.count.should eq(1)
    end

    it "maps datafield[@tag='110'][subfield[@code='e']='Creator (cre)'] and datafield[@tag='710'][subfield[@code='e']='source'] to agent_corporate_entity linked as 'creator'" do
      links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
      links.select {|l| l['role'] == 'creator'}.count.should eq(2)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='a'] to agent_corporate_entity.names[].primary_name" do
      @corps.select{|c| c['names'][0]['primary_name'] == 'CNames-PrimaryName-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='b'][1] to agent_corporate_entity.names[].subordinate_name_1" do
      @corps.select{|c| c['names'][0]['subordinate_name_1'] == 'CNames-Subordinate1-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='b'][2] to agent_corporate_entity.names[].subordinate_name_2" do
      # not a typo, per the tracer DB:
      @corps.select{|c| c['names'][0]['subordinate_name_2'] == 'CNames-Subordiate2-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='610' or @tag='110' or @tag='710']/subfield[@tag='b'] to linked_agent_corporate_entity.relator" do
      links = @resource['linked_agents'].select {|a| @corps.map{|c| c['uri']}.include?(a['ref'])}
      links.map {|l| l['relator']}.compact.sort.should eq(['source','Creator (cre)'].sort)
    end

    it "prepends and maps datafield[@tag='110' or @tag='610' or @tag='710']/subfield[@code='g'] to agent_corporate_entity.names[].qualifier" do
      @corps.select{|p| p['names'][0]['qualifier'] == "Miscellaneous information: CNames-Qualifier-AT."}.count.should eq(3)
    end

    it "maps datafield[@tag='110' or @tag='610' or @tag='710']/subfield[@code='n'] to agent_corporate_entity.names[].number" do
      @corps.select{|p| p['names'][0]['number'] == 'CNames-Number-AT'}.count.should eq(3)
    end

    it "maps datafield[@tag='245'] to resource.title using template '$a : $b [$h] $k , $n , $p , $s / $c' " do
      @resource['title'].should eq("Resource--Title-AT")
    end

    it "maps datafield[@tag='245']/subfield[@code='f' or @code='g'] to resources.dates[]" do
      @resource['dates'][1]['expression'].should eq("Resource-Date-Expression-AT-1960 - 1970")
    end

    it "maps datafield[@tag='300'] to resource.extents[].container_summary using template '$3: $a ; $b, $c ($e, $f, $g)'" do
      @resource['extents'][0]['container_summary'].should eq("5.0 Linear feet (Resource-ContainerSummary-AT)")
    end

    it "maps datafield[@tag='351'] to resource.notes[] using template '$3: $a. $b. $c'" do
      note_content(@notes[0]).should eq('Resource-Arrangement-Note Resource-FilePlan-AT.')
      # get_notes_by_string(@notes, 'Resource-Arrangement-Note Resource-FilePlan-AT.').count.should eq(1)
    end

    it "maps datafield[@tag='500'] to resource.notes[] using template '$3: $a'" do
      note_content(@notes[5]).should eq('Material Specific Details:Resource-MaterialSpecificDetails-AT')
    end

    it "maps datafield[@tag='506'] to resource.notes[] using template '$3: $a, $b, $c, $d, $e, $u.'" do
      note_content(@notes[11]).should eq('Resource-ConditionsGoverningAccess-AT.')
    end

    it "maps datafield[@tag='520'] to resource.notes[] using template '$3:  $a. ($u) [line break] $b.'" do
      note_content(@notes[12]).should eq('Resource-Abstract-AT.')
      @notes[12]['label'].should eq("Summary")
    end

    it "maps datafield[@tag='524'] to resource.notes[] using template '$3: $a. $2.'" do
      note_content(@notes[14]).should eq('Resource-PreferredCitation-AT.')
    end

    it "maps datafield[@tag='535'] to resource.notes[] using template 'Indicator 1 [Holder of originals | Holder of duplicates]: $3--$a. $b, $c. $d ($g).'" do
      note_content(@notes[16]).should eq('Indicator 1 Holder of originals: Resource-ExistenceLocationOriginals-AT.')
    end

    it "maps datafield[@tag='540'] to resource.notes[] using template '$3: $a. $b. $c. $d ($u).'" do
      note_content(@notes[17]).should eq('Resource-ConditionsGoverningUse-AT.')
    end

    it "maps datafield[@tag='541'] to resource.notes[] using template '#3: Source of acquisition--$a. Address--$b. Method of acquisition--$c; Date of acquisition--$d. Accession number--$e: Extent--$n; Type of unit--$o. Owner--$f. Purchase price--$h.'" do
      note_content(@notes[19]).should eq('Source of acquisition--Resource-ImmediateSourceAcquisition.')
    end

    it "maps datafield[@tag='544'] to resource.notes[] using template 'Indicator 1 [ Associated Materials | Related Materials]--$3: Title--$t. Custodian--$a: Address--$b, Country--$c. Provenance--$e. Note--$n.'" do
      note_content(@notes[20]).should eq('Custodian--Resource-RelatedArchivalMaterials-AT.')
    end

    it "maps datafield[@tag='545'] to resource.notes[] using template '$a ($u). [Line break] $b.'" do
      note_content(@notes[21]).should eq('Resource-BiographicalHistorical-AT.')
    end

    it "maps datafield[@tag='546'] to resource.notes[] using template '$3: $a ($b).'" do
      note_content(@notes[22]).should eq('Resource-LanguageMaterials-AT.')
      @notes[22]['label'].should eq('Language of Material')
    end

    it "maps datafield[@tag='561'] to resource.notes[] using template '$3: $a.'" do
      note_content(@notes[23]).should eq('Resource--CustodialHistory-AT.')
    end

    it "maps datafield[@tag='630'] to subject" do
      s = @subjects.select{|s| s['terms'][0]['term'] == 'Subjects--Uniform Title--AT'}
      s.count.should eq(1)
      s.last['source'].should eq('Local sources')
    end

    it "maps datafield[@tag='650'] to subject" do
      s = @subjects.select{|s| s['terms'][0]['term'] == 'Subjects--Topical Term--AT'}
      s.last['terms'][0]['term_type'].should eq('topical')
      s.count.should eq(1)
      s.last['source'].should eq('Local sources')
    end
  end
end
