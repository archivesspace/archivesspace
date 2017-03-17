require_relative 'spec_helper'

describe "Search" do

  before(:all) do
    @repo = create(:repo, :repo_code => "search_test_#{Time.now.to_i}", :publish => true)
    set_repo @repo

    @accession = create(:accession,
                        :title => "A test accession #{Time.now.to_i}_#{$$}")
    
    @accession2 = create(:accession,
                        :title => "Another test accession #{Time.now.to_i}_#{$$}",
                        :content_description => "old moldy newspapers found in a dumpster")

    @manager_user = create_user(@repo => ['repository-managers'])

    @driver = Driver.get.login_to_repo(@manager_user, @repo)

    run_all_indexers
  end


  after(:all) do
    @driver.quit
  end


  it "supports global searches" do
    @driver.find_element(:id, 'global-search-button').click
    assert(5) { @driver.find_element_with_text("//h2", /Search Results/) }
  end


  it "supports filtering global searches by type" do
    @driver.find_element(:id, 'global-search-button').click
    @driver.find_element(:link, "Accession").click
    assert(5) { @driver.find_element_with_text("//h5", /Filtered By/) }
    assert(5) { @driver.find_element_with_text("//a", /Record Type: Accession/) }
    assert(5) { @driver.find_element_with_text('//div', /Showing .*2.* of.*Results/) }
    assert(5) { @driver.find_element_with_text("//td", /#{@accession.title}/) }
    assert(5) { @driver.find_element_with_text("//td", /#{@accession2.title}/) }
  end
  
  it "supports some basic fulltext search globally" do
    @driver.clear_and_send_keys([:id => "global-search-box"], 'newspapers')
    @driver.find_element(:id, 'global-search-button').click
    assert(5) { @driver.find_element_with_text('//div', /Showing 1.* of.*Results/) }
    assert(5) { @driver.find_element_with_text("//td", /#{@accession2.title}/) }
  end
    

end

describe "Advanced Search" do

  before(:all) do
    @repo = create(:repo,
                   :repo_code => "adv_search_test_#{Time.now.to_i}",
                   :publish => true)
    set_repo @repo

    @keywords = (0..9).to_a.map { SecureRandom.hex }

    @accession_1 = create(:accession,
                          :title => "#{@keywords[0]} #{@keywords[4]}",
                          :publish => true)
    @accession_2 = create(:accession,
                          :title => "#{@keywords[1]} #{@keywords[5]}",
                          :publish => false)

    @resource_1 = create(:resource,
                         :title => "#{@keywords[0]} #{@keywords[6]}",
                         :publish => false)

    @resource_2 = create(:resource,
                         :title => "#{@keywords[2]} #{@keywords[7]}",
                         :publish => true)

    @digital_object_1 = create(:digital_object,
                               :title => "#{@keywords[0]} #{@keywords[8]}")
    @digital_object_2 = create(:digital_object,
                               :title => "#{@keywords[3]} #{@keywords[9]}")

    run_index_round

    @driver = Driver.get.login_to_repo($admin, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "is available via the navbar and renders when toggled" do
    @driver.find_element(:css => ".navbar .search-switcher").click
    @driver.find_element(:css => ".search-switcher-hide")
  end


  it "finds matches with one keyword field query" do
    @driver.clear_and_send_keys([:id => "v0"], @keywords[0])

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    # result list should contain those items with the @keywords[0] in the title
    @driver.find_element_with_text("//td", /#{@accession_1.title}/)
    @driver.find_element_with_text("//td", /#{@resource_1.title}/)
    @driver.find_element_with_text("//td", /#{@digital_object_1.title}/)

    # these records should not appear in the results
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2.title}')]")
  end


  it "finds single match with two keyword ANDed field queries" do
    # add a 2nd query row
    @driver.find_element(:css => ".advanced-search-add-row-dropdown").click
    @driver.find_element(:css => ".advanced-search-add-text-row").click

    @driver.clear_and_send_keys([:id => "v0"], @keywords[0])
    @driver.clear_and_send_keys([:id => "v1"], @keywords[4])
    @driver.find_element(:id => "f1").select_option("title")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    # result list should contain those items with a keyword @keywords[0]
    # and with the title containing @keywords[4]
    @driver.find_element_with_text("//td", /#{@accession_1.title}/)

    # and these results should no longer be there
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_1.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_1.title}')]")

    # these records should not appear in the results
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2.title}')]")
  end

  it "finds matches with two keyword ORed field queries" do
    @driver.find_element(:id => "op1").select_option("OR")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    # result list should contain those items with both @keywords[0] and @keywords[4]
    @driver.find_element_with_text("//td", /#{@accession_1.title}/)
    @driver.find_element_with_text("//td", /#{@resource_1.title}/)
    @driver.find_element_with_text("//td", /#{@digital_object_1.title}/)

    # these records should not appear in the results
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2.title}')]")
  end


  it "finds matches with two keyword joined AND NOTed field queries" do
    @driver.find_element(:id => "op1").select_option("NOT")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    # result list should contain those items with both @keywords[0] and NOT @keywords[4]
    @driver.find_element_with_text("//td", /#{@resource_1.title}/)
    @driver.find_element_with_text("//td", /#{@digital_object_1.title}/)
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_1.title}')]")

    # these records should not appear in the results
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_2.title}')]")
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@digital_object_2.title}')]")
  end


  it "clear resets the fields" do
    @driver.click_and_wait_until_gone(:css => ".advanced-search .reset-advanced-search")

    @driver.find_element(:id => "v0").attribute("value").should eq("")
  end

  it "allow adding of mulitple rows of the same type" do
    # in response to a bug
    @driver.find_element(:css => ".advanced-search-add-row-dropdown").click
    @driver.find_element(:css => ".advanced-search-add-bool-row").click
    @driver.find_element(:css => ".advanced-search-add-row-dropdown").click
    @driver.find_element(:css => ".advanced-search-add-bool-row").click

    @driver.find_element(:id => "v1")
    @driver.find_element(:id => "v2")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .reset-advanced-search")
  end

  it "filters records based on a boolean search" do
    # Let's find all records with keyword 1
    @driver.clear_and_send_keys([:id => "v0"], @keywords[0])
    @driver.find_element(:id => "f0").select_option("title")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    @driver.find_element_with_text("//td", /#{@accession_1.title}/)
    @driver.find_element_with_text("//td", /#{@resource_1.title}/)

    # add a boolean field row
    @driver.find_element(:css => ".advanced-search-add-row-dropdown").click
    @driver.find_element(:css => ".advanced-search-add-bool-row").click

    # let's only find those that are unpublished
    @driver.find_element(:id => "f1").select_option("published")
    @driver.find_element(:id => "v1").select_option("false")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    @driver.find_element_with_text("//td", /#{@resource_1.title}/)
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@accession_1.title}')]")

    # now let's flip it to find those that are published
    @driver.find_element(:id => "v1").select_option("true")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    @driver.find_element_with_text("//td", /#{@accession_1.title}/)
    @driver.ensure_no_such_element(:xpath, "//td[contains(text(), '#{@resource_1.title}')]")

  end


  it "filters records based on a date field search" do
    @driver.find_element(:css => ".advanced-search-add-row-dropdown").click
    @driver.find_element(:css => ".advanced-search-add-date-row").click

    # let's find all records created after 2014
    @driver.clear_and_send_keys([:id => "v2"], "2012-01-01")
    @driver.find_element(:id => "op2").select_option("AND")
    @driver.find_element(:id => "f2").select_option("create_time")
    @driver.find_element(:id => "dop2").select_option("greater_than")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    @driver.find_element_with_text("//td", /#{@accession_1.title}/)

    # change to lesser than.. there should be no results!
    @driver.find_element(:id => "dop2").select_option("lesser_than")

    @driver.click_and_wait_until_gone(:css => ".advanced-search .btn-primary")

    @driver.find_element_with_text('//p[contains(@class, "alert-info")]', /No records found/)
  end


  it "hides when toggled" do
    advanced_search_form = @driver.find_element(:css => "form.advanced-search")

    @driver.find_element(:link => "Hide Advanced Search").click

    expect {
      assert(100) {
        raise "Advanced Search still visible" if advanced_search_form.displayed?
      }
    }.not_to raise_error

  end


  it "doesn't display when a normal search is performed" do
    @driver.clear_and_send_keys([:id => "global-search-box"], @keywords[0])
    @driver.find_element(:id => "global-search-button").click

    @driver.ensure_no_such_element(:css => "form.advanced-search")
  end
end
