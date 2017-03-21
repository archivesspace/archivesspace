require_relative 'spec_helper'

describe "ArchivesSpace Public interface" do

  before(:all) do
    @repo = create(:repo, :publish => true)
    set_repo(@repo)

    @driver = Driver.new.go_home
  end


  # Stop selenium, kill the dev servers
  after(:all) do
    report_sleep
    @driver.quit
    cleanup
  end


  def self.xdescribe(*stuff)
  end

  after(:each) do |example|
    if example.exception and ENV['SCREENSHOT_ON_ERROR']
      SeleniumTest.save_screenshot(@driver)
    end
  end


  describe "Homepage" do

    it "is visible" do
      @driver.find_element_with_text('//h3', /Welcome to ArchivesSpace./)
    end

  end


  describe "Repositories" do

    before(:all) do
      @test_repo_code_1 = "test1#{Time.now.to_i}_#{$$}"
      @test_repo_name_1 = "test repository 1 - #{Time.now}"
      @test_repo_code_2 = "test2#{Time.now.to_i}_#{$$}"
      @test_repo_name_2 = "test repository 2 - #{Time.now}"

      create(:repo,
             :repo_code => @test_repo_code_1,
             :name => @test_repo_name_1,
             :publish => true)
      create(:repo,
             :repo_code => @test_repo_code_2,
             :name => @test_repo_name_2,
             :publish => true)

      run_index_round
    end


    it "lists all available repositories" do
      @driver.click_and_wait_until_gone(:link, "Repositories")
      @driver.find_element_with_text('//a', /#{@test_repo_code_1}/)
      @driver.find_element_with_text('//a', /#{@test_repo_code_2}/)
    end

    it "shows Title (default)  in the sort pulldown" do
      @driver.click_and_wait_until_gone(:link, "Repositories")
      @driver.find_element(:xpath, "//a/span[ text() = 'Title Ascending']").click
      @driver.find_element(:link, "Title" )
      @driver.ensure_no_such_element(:link, "Term")
    end

  end


  describe "Resources" do

    before(:all) do
      @note1 = "BOOO!"
      @note2 = "Manny Moe"
      @note1_html ="<emph render='bold'>#{@note1}</emph>"
      @note2_html = "<name>#{@note2}</name>"

      notes = [{"jsonmodel_type" => "note_singlepart", "publish" => true, "type" => "abstract", "content" => ["moo"]},
              {"jsonmodel_type" => "note_multipart", "publish" => true,"type" => "accruals", "content" => ["moo"],
                "label" => "moo", "subnotes" => [{"publish" => true,"jsonmodel_type" => "note_definedlist",
                "items" => [{ "value" => @note1_html,  "label" => "should_have_been_an_object" }] }]},
              {"jsonmodel_type" => "note_multipart","publish" => true, "type" => "accruals", "content" => ["moo"],
                "label" => "moo", "subnotes" => [{"publish" => true,"jsonmodel_type" => "note_orderedlist",
                "items" => [ @note2_html ] }]}

      ]

      @unpublished = create(:resource,
                            :title => "Unpublished Resource", :publish => false, :id_0 => "unpublished")
      @published = create(:resource,
                          :title => "Published Resource", :publish => true, :id_0 => "published", :notes => notes)

      run_index_round
    end


    it "doesn't list an un-published records in the list" do
      @driver.click_and_wait_until_gone(:link, "Collections")

      @driver.find_element(:link, @published.title)
      @driver.ensure_no_such_element(:link, @unpublished.title)
    end


    it "throws a 404 when trying to access an un-processed resource" do
      @driver.get(URI.join($frontend, @unpublished.uri))
      @driver.find_element_with_text('//h2', /Record Not Found/)
    end

    it "shows a record that is published" do

      @driver.get(URI.join($frontend, @published.uri))

      @driver.find_element_with_text('//h2', /#{@published.title}/ )

      @driver.ensure_no_such_text("//dd", /\<emph/)
      @driver.ensure_no_such_text("//li", /\<name/)

      @driver.find_element_with_text('//span', /#{@note1}/ )
      @driver.find_element_with_text('//li', /#{@note2}/ )

    end


    it "uses the finding_aid_title if there is one" do


      @published = create(:resource,
                          :title => "NO WAY", :id_0 => rand(1000).to_s,  :finding_aid_filing_title => "YeaBuddy",
                          :publish => true )

      run_index_round

      @driver.click_and_wait_until_gone(:link, "Collections")

      @driver.click_and_wait_until_gone(:link, "YeaBuddy")

      @driver.find_element_with_text('//li', /YeaBuddy/ )
      @driver.find_element_with_text('//h2', /YeaBuddy/ )

    end

    it "offers pagination when there are more than 10" do
      11.times.each do |i|
        create(:resource,
               :title => "Test Resource #{i}", :publish => true, :id_0 => "id#{i}")
      end

      run_index_round

      @driver.click_and_wait_until_gone(:link, "Collections")

      expect(@driver.find_element(:css, '.pagination .active a').text).to eq('1')

      @driver.click_and_wait_until_gone(:link, '2')
      expect(@driver.find_element(:css, '.pagination .active a').text).to eq('2')

      @driver.click_and_wait_until_gone(:link, '1')
      expect(@driver.find_element(:css, '.pagination .active a').text).to eq('1')
      @driver.find_element(:link, '2')
    end

  end

  describe "Digital Objects" do
    before(:all) do
      @published_digital_object = create(:digital_object,
                                           :title => "Published DO",
                                           :publish => true,
                                           :file_versions => [
                                                              { :file_uri => "https://archivesssss.xxx", :publish => true},
                                                              { :file_uri => "http://boo.eu", :publish => false },
                                                              { :file_uri => "C:\\windozefilepaths.suck", :publish => true },
                                                              { :file_uri => "file:///C:\\uris.dont", :publish => true }
                                                             ])
      run_index_round
    end

    it "displayed the digital object correctly" do
      @driver.get(URI.join($frontend, @published_digital_object.uri))
      @driver.find_element_with_text('//h2', /#{@published_digital_object.title}/)
      @driver.find_element_with_text('//h3', /File Versions/)
      @driver.find_element(:link ,"https://archivesssss.xxx" )
      @driver.ensure_no_such_element( :link,"http://boo.eu")
      @driver.ensure_no_such_element( :link,"C:\\windozefilepaths.suck")
      @driver.find_element(:link ,"file:///C:/uris.dont" )
    end
  end

  describe "Archival Objects" do

    before(:all) do
      @published_resource_filing_title = "FilingTitle"

      @unpublished_resource = create(:resource, :publish => false)
      @published_resource = create(:resource,
                                   :publish => true,
                                   :finding_aid_filing_title => @published_resource_filing_title)

      @published_archival_object = create(:archival_object,
                                          :publish => true,
                                          :resource => {:ref => @published_resource.uri})

      @unpublished_archival_object = create(:archival_object,
                                          :publish => false,
                                          :resource => {:ref => @unpublished_resource.uri})

      run_index_round
    end


    it "renders index notes as links when they contain ref_ids of other components" do
      index_link_text = "a sweet link"
      ref_id = @published_archival_object.ref_id

      ao_with_note = create(:archival_object,
                            :title => "AO with an index note",
                            :publish => true,
                            :resource => {:ref => @published_resource.uri},
                            :notes => [{:jsonmodel_type => "note_index",
                                         :publish => true,
                                         :items => [{:jsonmodel_type => "note_index_item",
                                                      :type => "name",
                                                      :value => "something",
                                                      :reference => ref_id,
                                                      :reference_text => index_link_text}]}])
      run_index_round

      @driver.get(URI.join($frontend, ao_with_note.uri))
      @driver.click_and_wait_until_gone(:link, index_link_text)
      @driver.find_element_with_text('//li', /#{@published_resource_filing_title}/ )
      @driver.find_element_with_text('//h2', /#{@published_archival_object.title}/)
    end


    it "is visible in the published resource children list and can be viewed" do
      @driver.get(URI.join($frontend, @published_resource.uri))

      @driver.find_element(:link, @published_archival_object.title)

      @driver.get(URI.join($frontend, @published_archival_object.uri))
      @driver.find_element_with_text('//h2', /#{@published_archival_object.title}/)
    end


    it "doesn't allow viewing of an unpublished archival object" do
      @driver.get(URI.join($frontend, @unpublished_archival_object.uri))
      @driver.find_element_with_text('//h2', /Record Not Found/)
    end

  end


  describe "Agents" do

    before(:all) do
      contact =  { "name" => "Home", "salutation" => "mr", "address_1" => "123 Fake St.",
      "city" => "Springfield"}
      @unpublished_agent = create(:agent_person,
                                  :names => [build(:name_person,
                                                  :primary_name => "Unpubished Dude")],
                                  :publish => false)

      @published_agent = create(:agent_person,
                                :names => [build(:name_person,
                                                :primary_name => "Published Dude")],
                                :publish=> true,
                                :agent_contacts => [contact])

      @published_resource = create(:resource,
                                   :title => "Published Resource No.3",
                                   :publish => true,
                                   :id_0 => "published3",
                                   :linked_agents => [
                                                      {:ref => @unpublished_agent.uri, :role => 'creator'},
                                                      {:ref => @published_agent.uri, :role => 'creator'},
                                                     ]
                                   )

      run_index_round
    end


    it "published are visible in the names search results" do
      @driver.click_and_wait_until_gone(:link, "Names")

      @driver.find_element(:link, @published_agent.names.first['sort_name'])
      assert(5) {
        @driver.ensure_no_such_element(:link, @unpublished_agent.names.first['sort_name'])
      }
    end

    it "linked records show for an agent search" do
      @driver.click_and_wait_until_gone(:link, @published_agent.names.first['sort_name'])
      @driver.find_element(:link, @published_resource.title)
      @driver.ensure_no_such_element(:xpath, "//*[text()[contains( '1234 Fake St')]]")
      @driver.ensure_no_such_element(:css, '#contacts')
    end

    it "linked record shows published agents in the list" do
      @driver.click_and_wait_until_gone(:link, @published_resource.title)
      @driver.find_element(:link, @published_agent.names.first['sort_name'])
      @driver.ensure_no_such_element(:link, @unpublished_agent.names.first['sort_name'])
    end

    it "shows the Agent Name in the sort pulldown" do
      @driver.click_and_wait_until_gone(:link, "Names")
      @driver.find_element(:xpath, "//a/span[ text()  = 'Agent Name Ascending']").click
      @driver.find_element(:link, "Agent Name" )
      @driver.ensure_no_such_element(:link, "Title")
    end
  end


  describe "Subjects" do
    before(:all) do
      @linked_subject = create(:subject)
      @not_linked_subject = create(:subject)

      @published_resource = create(:resource,
                                   :title => "Published Resource No.4",
                                   :publish => true,
                                   :id_0 => "published4",
                                   :subjects => [
                                                 {:ref => @linked_subject.uri}
                                                ]
                                   )

      run_index_round
    end

    it "is visible when it is linked to a published resource" do
      @driver.click_and_wait_until_gone(:link, "Subjects")
      @driver.find_element(:link, @linked_subject.title)
    end

    it "is not visible when it not linked to a published resource" do
      @driver.ensure_no_such_element(:link, @not_linked_subject.title)
    end

    it "shows the Term  in the sort pulldown" do
      @driver.click_and_wait_until_gone(:link, "Subjects")
      @driver.find_element(:xpath, "//a/span[ text()  = 'Terms Ascending']").click
      @driver.find_element(:link, "Terms" )
      @driver.ensure_no_such_element(:link, "Title")
    end
  end

  describe "Search" do
    before(:all) do

      @published_resource = create(:resource,
                                   :title => "The meaning of life papers",
                                   :publish => true,
                                   :id_0 => "themeaningoflifepapers")

      @published_resource1 = create(:resource,
                                    :title => "The meaning of death papers",
                                    :publish => true,
                                    :id_0 => "themeaningofdeathpapers")

      run_index_round
    end

    before(:each) do
      @driver.click_and_wait_until_gone(:css, 'a span[class="icon-home"]')
    end

    it "finds the published resource with a basic search" do
      @driver.clear_and_send_keys([:class, 'input-large'], "The meaning of life papers")
      @driver.click_and_wait_until_gone(:id, "global-search-button")
      @driver.find_element(:link, "The meaning of life papers")
    end

    it "finds the published resource with an advanced search (default AND)" do
      @driver.find_element(:link, 'Show Advanced Search').click

      @driver.clear_and_send_keys([:id, 'v0'], "meaning")
      @driver.clear_and_send_keys([:id, 'v1'], "life")
      @driver.clear_and_send_keys([:id, 'v2'], "papers")

      search_button = @driver.find_element_with_text("//button", /Search/)
      @driver.click_and_wait_until_element_gone(search_button)

      @driver.find_element(:link, "The meaning of life papers")
      @driver.ensure_no_such_element(:link, "The meaning of death papers")
    end

    it "finds the published resources with an OR advanced search" do
      @driver.find_element(:link, 'Show Advanced Search').click

      @driver.clear_and_send_keys([:id, 'v0'], "meaning")
      @driver.clear_and_send_keys([:id, 'v1'], "life")
      @driver.find_element(:id => "op2").select_option("OR")
      @driver.clear_and_send_keys([:id, 'v2'], "death")

      search_button = @driver.find_element_with_text("//button", /Search/)
      @driver.click_and_wait_until_element_gone(search_button)

      ["The meaning of life papers", "The meaning of death papers"].each do |title|
        @driver.find_element(:link, title)
      end
    end

    it "finds the appropriate published resource with a NOT advanced search" do
      @driver.find_element(:link, 'Show Advanced Search').click

      @driver.clear_and_send_keys([:id, 'v0'], "meaning")
      @driver.clear_and_send_keys([:id, 'v1'], "life")
      @driver.find_element(:id => "op2").select_option("NOT")
      @driver.clear_and_send_keys([:id, 'v2'], "death")

      search_button = @driver.find_element_with_text("//button", /Search/)
      @driver.click_and_wait_until_element_gone(search_button)

      @driver.find_element(:link, "The meaning of life papers")
      @driver.ensure_no_such_element(:link, "The meaning of death papers")
    end
  end

end
