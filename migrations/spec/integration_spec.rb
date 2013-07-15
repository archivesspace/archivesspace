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
    Array(note['content']).join(" ")
  else
    get_subnotes_by_type(note, 'note_text').map {|sn| sn['content']}.join(" ").gsub(/\n +/, "\n")
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

def get_marc_doc(repo_id, resource_id)
  uri = URI.parse("#{$backend_url}/repositories/#{repo_id}/resources/marc21/#{resource_id}.xml")
  response = JSONModel::HTTP.get_response(uri)
  doc = Nokogiri::XML::Document.parse(response.body)
  doc.remove_namespaces!

  doc.instance_eval do
    def df(tag, ind1=nil, ind2=nil)
      selector ="@tag='#{tag}'"
      selector += " and @ind1='#{ind1}'" if ind1
      selector += " and @ind2='#{ind2}'" if ind2
      datafields = self.xpath("//datafield[#{selector}]")
      datafields.instance_eval do
        def sf(code)
          self.xpath("subfield[@code='#{code}']")
        end
        def sf_t(code)
          sf(code).inner_text
        end
      end

      datafields
    end
  end

  doc
end

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
  when 'genre_form', 'style_period'; 'v'
  when 'topical', 'cultural_context'; 'x'
  when 'temporal'; 'y'
  when 'geographic'; 'z'
  end
end

def test_person_name(df, name)
  name_string = %w(primary_ rest_of_).map{|p| name["#{p}name"]}.reject{|n| n.nil? || n.empty?}\
                                                               .join(name['name_order'] == 'direct' ? ' ' : ', ')

  df.sf_t('a').should include(name_string)
  df.sf_t('b').should include(name['number'])
  df.sf_t('c').should include(%w(prefix title suffix).map{|p| name[p]}.compact.join(', '))
  df.sf_t('d').should include(name['dates'])
  df.sf_t('q').should include(name['fuller_form'])
end

def test_family_name(df, name)
  df.sf_t('a').should include(name['family_name'])
  df.sf_t('c').should include(name['prefix'])
  df.sf_t('d').should include(name['dates'])
end

def test_corporate_name(df, name)
  df.sf_t('a').should include(name['primary_name'])
  df.sf_t('b').should include(name['subordinate_name_1']+name['subordinate_name_2'])
  df.sf_t('n').should include(name['number'])
end

describe 'ASpaceImport' do

  before(:all) do
    start_backend
    @vocab_uri = make_test_vocab
  end

  after(:each) do
    @opts = {}
  end

  after(:all) do
    stop_backend
  end

  describe "ASpace Import, General" do

    before(:each) do
      @repo = create(:json_repo)
      @repo_id = @repo.class.id_for(@repo.uri)

      @opts = {
        :repo_id => @repo_id,
        :vocab_uri => build(:json_vocab).class.uri_for(2)
      }
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
      i['container']['indicator_1'].should eq('2')
      i['container']['indicator_2'].should eq('2')
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

  describe "MARC export mappings" do
    before(:all) do
      $old_enum_source = JSONModel.init_args[:enum_source]
      JSONModel.init_args[:enum_source] = JSONModel::Client::EnumSource.new

      @repo = create(:json_repo)
      JSONModel.set_repository(@repo.id)

      @agents = {}
      20.times {
        a = create([:json_agent_person, :json_agent_corporate_entity, :json_agent_family].sample)
        @agents[a.uri] = a
      }

      @subjects = {}
      20.times {
       s = create(:json_subject)
       @subjects[s.uri] = s
      }

      date = build(:json_date)
      if rand(2) == 1
        date['expression'] = nil
      end

      note_types = %w(odd dimensions physdesc materialspec physloc phystech physfacet processinfo separatedmaterial \
                      arrangement fileplan accessrestrict abstract scopecontent prefercite acqinfo)
      notes = []
      brake = 0
      while !(note_types - notes.map {|note| note['type']}).empty? && brake < 500 do
        notes << build("json_note_#{['singlepart', 'multipart', 'index', 'bibliography'].sample}".intern, {
                                                                                                      :publish => [true, false].sample
                                                                                                    })
        brake += 1
      end

      @resource = create(:json_resource, :linked_agents => @agents.map{|ref, a| {:ref => ref,
                                                                                :role => (ref[-1].to_i % 2 == 0 ? 'creator' : 'subject'),
                                                                                :terms => [build(:json_term), build(:json_term)],
                                                                                :relator => (ref[-1].to_i % 4 == 0 ? generate(:relator) : nil)
                                                                                }
                                                                      },
                                          :dates => [date],
                                          :notes => notes,
                                          :subjects => @subjects.map{|ref, s| {:ref => ref}}
                        )

      @doc = get_marc_doc(@repo.id, @resource.id)
    end

    after(:all) do
      JSONModel.init_args[:enum_source] = $old_enum_source
    end

    it "provides default values for record/leader: 00000np$ a2200000 u 4500" do
      @doc.xpath("//record/leader").inner_text.should match(/00000np.\sa2200000\su\s4500/)
    end

    it "maps resource.level to record/leader[7]" do
      @doc.xpath("//record/leader").inner_text[7].should eq(@resource.level == 'item' ? 'm' : 'c')
    end

    it "maps resource record mtime to record/controlfield[@tag='008']/text()[0..5]" do
      @doc.xpath("//record/controlfield").inner_text[0..5].should match(/\d{6}/)
    end

    #IF resource.level = "item" and date[0].date_type = 'single', THEN "s"
    it "sets record/controlfield[@tag='008']/text()[6] according to resource.level" do
      whatitshouldbe = (@resource.level == 'item' && @resource.dates[0]['date_type'] == 'single' ? 's' : 'i')
      @doc.xpath("//record/controlfield").inner_text[6].should eq(whatitshouldbe)
    end

    it "sets record/controlfield[@tag='008']/text()[7..10] with resource.dates[0]['begin']" do
      whatitshouldbe = @resource.dates[0]['begin'] ? @resource.dates[0]['begin'][0..3] : "    "
      @doc.xpath("//record/controlfield").inner_text[7..10].should eq(whatitshouldbe)
    end

    it "sets record/controlfield[@tag='008']/text()[11..14] with resource.dates[0]['end']" do
      unless (@resource.level == 'item' && @resource.dates[0]['date_type'] == 'single')
        whatitshouldbe = @resource.dates[0]['end'] ? @resource.dates[0]['end'][0..3] : "    "
        @doc.xpath("//record/controlfield").inner_text[11..14].should eq(whatitshouldbe)
      end
    end

    it "sets record/controlfield[@tag='008']/text()[15..16] with 'xx'" do
      @doc.xpath("//record/controlfield").inner_text[15..16].should eq('xx')
    end

    it "sets record/controlfield[@tag='008']/text()[35..37] with resource.language" do
      @doc.xpath("//record/controlfield").inner_text[35..37].should eq(@resource.language)
    end

    it "sets record/controlfield[@tag='008']/text()[38..39] with ' d'" do
      @doc.xpath("//record/controlfield").inner_text[38..39].should eq(' d')
    end

    it "maps repository.org_code to datafield[@tag='040' and @ind1=' ' and @ind2=' '] subfields a and c" do
      @doc.df('040', ' ', ' ').sf_t('a').should eq(@repo.org_code)
      @doc.df('040', ' ', ' ').sf_t('c').should eq(@repo.org_code)
    end

    it "maps resource.finding_aid_description_rules to df[@tag='040' and @ind1=' ' and @ind2=' ']/sf[@code='e']" do
      @doc.df('040', ' ', ' ').sf_t('e').should eq(@resource.finding_aid_description_rules)
    end

    it "maps resource.language to df[@tag='041' and @ind1='0' and @ind2=' ']/sf[@code='a']" do
      @doc.df('041', '0', ' ').sf_t('a').should eq(@resource.language)
    end

    it "maps resource.id_\\d to df[@tag='099' and @ind1=' ' and @ind2=' ']/sf[@code='a']" do
      @doc.df('099', ' ', ' ').sf_t('a').should eq((0..3).map {|i|@resource.send("id_#{i}") }.join('.'))
    end

    it "maps the first creator to df[@tag='100'] or df[@tag='110']" do
      clink = @resource.linked_agents.find{|l| l[:role] == 'creator'}
      creator = @agents[clink[:ref]]
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
      if clink[:relator]
        df.sf_t('4').should eq(clink[:relator])
      else
        df.sf_t('e').should eq('creator')
      end
    end

    it "maps data to datafield[@tag='245' and @ind1='1' and @ind2='0']" do
      df = @doc.df('245', '1', '0')
      df.sf_t('a').should eq(@resource.title)
      date = @resource.dates[0]
      date_content = date['date_type'] == 'bulk' ? df.sf_t('g') : df.sf_t('f')
      if date['expression']
        date_content.should eq(date['expression'])
      elsif date['date_type'] == 'single'
        date_content.should eq(date['begin'])
      elsif date['date_type'] == 'inclusive'
        date_content.should eq("#{date['begin']} - #{date['end']}")
      end
    end

    it "maps extent data to datafield[@tag='300' and @ind1=' ' and @ind2=' ']" do
      df = @doc.df('300', ' ', ' ')
      df.sf('a').count.should eq(@resource.extents.count)
      df.sf_t('a').should eq(@resource.extents.map{|e| "#{e['number']} #{I18n.t('enumerations.extent_extent_type.'+e['extent_type'])}"}.join(''))
      df.sf_t('f').should eq(@resource.extents.map{|e| e['container_summary']}.join(''))
    end

    # specified, but not possible given validation rules
    # it "hardcodes datafield[@tag='300' and @ind1=' ' and @ind2=' '] when extents is empty" do
    #   df = @doc_b.df('300', ' ', ' ')
    #   df.sf_t('a').should eq('1 item')
    # end

    it "maps notes of type 'arrangement' and 'fileplan' to datafield[@tag='351' and @ind1=' ' and @ind2=' ']/subfield[@code='b']" do
      contents = @resource.notes.select{|n| ['arrangement', 'fileplan'].include?(n['type']) }.map {|n| note_content(n)}.sort
      xml_data = @doc.df('351', ' ', ' ').sf('b').map{|n| n.inner_text}.sort
      contents.should eq(xml_data)
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
      notes = @resource.notes.select{|n| n['type'] == 'accessrestrict'}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('506', ' ', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'abstract' to df 520 ('3', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(abstract).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('520', '3', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'scopecontent' to df 520 ('2', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(scopecontent).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('520', '2', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'prefercite' to df 534 ('8', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(prefercite).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('534', '8', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'altformavail' to df 535 ('2', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(altformavail).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('535', '2', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'originalsloc' to df 535 ('1', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(originalsloc).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('535', '1', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'userestrict' | 'legalstatus' to df 540 (' ', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(userestrict legalstatus).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('540', ' ', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps public notes of type 'acqinfo' to df 541 ('1', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(acqinfo).include?(n['type']) && n['publish']}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('541', '1', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps private notes of type 'acqinfo' to df 541 ('0', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(acqinfo).include?(n['type']) && !n['publish']}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('541', '0', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'relatedmaterial' to df 544 (' ', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(relatedmaterial).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('544', ' ', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'bioghist' to df 545 (' ', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(bioghist).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('545', ' ', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'langmaterial' to df 546 (' ', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(langmaterial).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('546', ' ', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps resource.ead_location to df 555 (' ', ' '), sf a" do
      df = @doc.df('555', ' ', ' ')
      df.sf_t('u').should eq(@resource.ead_location)
      df.sf_t('a').should eq("Finding aid online:")
    end

    it "maps public notes of type 'custodhist' to df 561 ('1', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(custodhist).include?(n['type']) && n['publish']}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('561', '1', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps private notes of type 'custodhist' to df 561 ('0', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(custodhist).include?(n['type']) && !n['publish']}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('561', '0', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps public notes of type 'appraisal' to df 583 ('1', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(appraisal).include?(n['type']) && n['publish']}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('583', '1', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps private notes of type 'appraisal' to df 583 ('0', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(appraisal).include?(n['type']) && !n['publish']}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('583', '0', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps notes of type 'accruals' to df 584 (' ', ' '), sf a" do
      notes = @resource.notes.select{|n| %w(accruals).include?(n['type'])}
      pending "a different sample" unless notes.count > 0
      xml_content = @doc.df('584', ' ', ' ').sf_t('a')
      xml_content.should_not be_empty
      notes.map{|n| note_content(n)}.join('').should eq(xml_content)
    end

    it "maps agents with 'subject' role to field 600|610" do
      subjects = @resource.linked_agents.select{|l| l[:role] == 'subject'}.map{|s| @agents[s[:ref]]}

      subjects.each do |subject|

        relator = @resource.linked_agents.find{|l| l[:ref] == subject.uri}[:relator]
        terms = @resource.linked_agents.find{|l| l[:ref] == subject.uri}[:terms]
        name = subject.names[0]
        df = nil

        ind2 =  source_to_code(subject['source'])

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
        subject = @subjects[link[:ref]]
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
      creators = @resource.linked_agents.select{|l| l[:role] == 'creator' || l[:role] == 'source'}[1..-1]

      creators.each do |link|
        creator = @agents[link[:ref]]
        relator = link[:relator]
        role = link[:role]
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
      df = @doc.df('852', ' ', ' ')
      df.sf_t('a').should include(@repo.org_code)
      df.sf_t('b').should eq(@repo.name)
      df.sf_t('c').should eq((0..3).map{|i| @resource.send("id_#{i}")}.compact.join('.'))
    end

    it "maps EAD location information to df 856" do
      df = @doc.df('856', '4', '2')
      df.sf_t('z').should eq('Finding aid online:')
      df.sf_t('u').should eq(@resource.ead_location)
    end
  end
end
