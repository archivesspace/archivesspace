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


  xit "can import the file at examples/ead/ferris.xml" do

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

    count.should eq(10)
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

    count.should eq(19)
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


    it "maps '<name>' correctly" do
    #  	IF nested in <origination> OR <controlaccess>
    # 	IF nested in <origination>
    # 	IF nested in <controlaccess>
    # 	ELSE
    # 	IF @rules != NULL
    # 	IF @source != NULL
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
      ref52['items'].find{|i| i['type'] == 'Family Name'}['value'].should eq('Bike 2')
    #         <corpname>
      ref52['items'].find{|i| i['type'] == 'Corporate Name'}['value'].should eq('Bike 3')
    #         <subject>

    #         <function>

    #         <occupation>

    #         <genreform>
      ref52['items'].find{|i| i['type'] == 'Genre Form'}['value'].should eq('Bike 1')
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

    it "maps '<daogrp>' correctly" do
    # 	EACH <daoloc> within <daogrp> treated as individual file_versions within a single digital_object instance.
    #   @role
    #   @href
    #   @label
    #   <daodesc>
    end

    # REFERENCES & IDENTIFIERS
    it "maps '<ptr>' correctly" do
    # 	id and target resolve to the note, subject, name, or archival_object in which reference occurs occurs.
    end

    it "maps '<ptrloc>' correctly" do
    # 	id and target resolve to the note, subject, name, or archival_object in which reference occurs occurs.
    end

    it "maps '<ref>' correctly" do
    # 	id and target resolve to the note, subject, name, or archival_object in which reference occurs occurs.
    end

    it "maps '<refloc>' correctly" do
    # 	id and target resolve to the note, subject, name, or archival_object in which reference occurs occurs.
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

    it "maps '<c01>' correctly" do
    #  through <c12>
    #   @level	IF != NULL
    # 	ELSE
    #   @otherlevel
    #   @id
    end

    # MIXED CONTENT
    # This list is not exclusive, some of the elements above are imported as mixed content in specific contexts (e.g. names).

    # it "maps '<abbr>' correctly" do
    # end
    #
    # it "maps '<address>' correctly" do
    # end
    #
    # it "maps '<addressline>' correctly" do
    # end
    #
    # it "maps '<archref>' correctly" do
    # end
    #
    # it "maps '<bibseries>' correctly" do
    # end
    #
    # it "maps '<blockquote>' correctly" do
    # end
    #
    # it "maps '<colspec>' correctly" do
    # end
    #
    # it "maps '<edition>' correctly" do
    # end
    #
    # it "maps '<emph>' correctly" do
    # end
    #
    # it "maps '<entry>' correctly" do
    # end
    #
    # it "maps '<expan>' correctly" do
    # end
    #
    # it "maps '<extptr>' correctly" do
    # end
    #
    # it "maps '<extptrloc>' correctly" do
    # end
    #
    # it "maps '<extref>' correctly" do
    # end
    #
    # it "maps '<extrefloc>' correctly" do
    # end
    #
    # it "maps '<imprint>' correctly" do
    # end
    #
    # it "maps '<label>' correctly" do
    # end
    #
    # it "maps '<language>' correctly" do
    # end
    #
    # it "maps '<lb>' correctly" do
    # end
    #
    # it "maps '<linkgrp>' correctly" do
    # end
    #
    # it "maps '<num>' correctly" do
    # end
    #
    # it "maps '<p>' correctly" do
    # end
    #
    # it "maps '<ptrgrp>' correctly" do
    # end
    #
    # it "maps '<publisher>' correctly" do
    # end
    #
    # it "maps '<resource>' correctly" do
    # end
    #
    # it "maps '<row>' correctly" do
    # end
    #
    # it "maps '<runner>' correctly" do
    # end
    #
    # it "maps '<table>' correctly" do
    # end
    #
    # it "maps '<tbody>' correctly" do
    # end
    #
    # it "maps '<tgroup>' correctly" do
    # end
    #
    # it "maps '<thead>' correctly" do
    # end
    #
    # it "maps '<titlepage>' correctly" do
    # end

    # NOT IMPORTED
    # '<arc>' '<archdescgrp>' '<creation>' '<descgrp>' '<dscgrp>'
    # '<eadgrp>' '<eadheader>' '<filedesc>' '<frontmatter>'
    # '<publicationstmt>' '<repository>' '<daogrp>'
  end
end
