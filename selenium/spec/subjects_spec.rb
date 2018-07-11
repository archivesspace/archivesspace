require_relative 'spec_helper'

describe "Subjects" do

  before(:all) do
    @repo = create(:repo)
    set_repo(@repo)

    @archivist_user = create_user(@repo => ['repository-archivists'])

    @driver = Driver.get
    @driver.login_to_repo(@archivist_user, @repo)
  end

  after(:all) do
    @driver.quit
  end

  it "reports errors and warnings when creating an invalid Subject" do
    @driver.get($frontend)

    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Subject')

    @driver.find_element(:css => '#subject_terms_.initialised')

    @driver.find_element(:css => '#subject_external_documents_ .subrecord-form-heading .btn:not(.show-all)').click

    @driver.find_element(:css => '#subject_terms_ .subrecord-form-remove').click
    @driver.find_element(:css => '#subject_terms_ .confirm-removal').click

    @driver.find_element(:css => "form .record-pane button[type='submit']").click

    # check messages
    expect {
      @driver.find_element_with_text('//div[contains(@class, "error")]', /Terms - At least 1 item\(s\) is required/)
    }.to_not raise_error
  end


  it "can create a new Subject" do
    now = "#{$$}.#{Time.now.to_i}"

    @driver.get($frontend)

    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Subject')

    @driver.find_element(:css => "#subject_terms_.initialised")

    @driver.find_element(:css => "form #subject_terms_.initialised button:not(.show-all)").click

    @driver.find_element(:id => "subject_source_").select_option("local")

    @driver.clear_and_send_keys([:id, "subject_terms__0__term_"], "just a term really #{now}")
    @driver.clear_and_send_keys([:id, "subject_terms__1__term_"], "really")
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    assert(5) { @driver.find_element(:css => '.record-pane h2').text.should eq("just a term really #{now} -- really Subject") }
  end

  it "can reorder the terms and have them maintain order" do
    @driver.get($frontend)

    first = "first_#{SecureRandom.hex}"
    second = "second_#{SecureRandom.hex}"

    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Subject')

    @driver.find_element(:css => '#subject_terms_.initialised')

    @driver.find_element(:css => "form #subject_terms_ button:not(.show-all)").click
    @driver.find_element(:id => "subject_source_").select_option("local")
    @driver.clear_and_send_keys([:id, "subject_terms__0__term_"], first)
    @driver.clear_and_send_keys([:id, "subject_terms__1__term_"], second)
    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    assert(5) { @driver.find_element(:css => '.record-pane h2').text.should eq("#{first} -- #{second} Subject") }

    #drag to become sibling of parent
    source = @driver.find_element( :css => "#subject_terms__1_ .drag-handle" )

    # Tuesday 14 March 14:33:42 AEDT 2017 -- selenium rejecting the negative Y
    # value here, which seems like a bug:
    #
    # https://github.com/mozilla/geckodriver/issues/527
    @driver.action.drag_and_drop_by(source, 0, -100).perform

    # I hate you for wasting my life.
    #
    # I concur.
    @driver.find_element( :id => "subject_terms_" ).click
    sleep(2)
    @driver.find_element(:css => "form .record-pane button[type='submit']").click
    @driver.find_element(:css => "form .record-pane button[type='submit']").click

    assert(5) { @driver.find_element(:css => '.record-pane h2').text.should eq("#{second} -- #{first} Subject") }

    # refresh the page and verify that the change really stuck
    @driver.navigate.refresh
    target = @driver.find_element( :css => "#subject_terms__0__term_" ).attribute('value').should eq(second)
    target = @driver.find_element( :css => "#subject_terms__1__term_" ).attribute('value').should eq(first)

  end

  it "can present a browse list of Subjects" do
    @driver.get($frontend)

    run_index_round

    @driver.find_element(:link => 'Browse').click
    @driver.click_and_wait_until_gone(:link => 'Subjects')

    expect {
      @driver.find_element_with_text('//tr', /just a term really/)
    }.to_not raise_error
  end
  

  it "can use plus+1 submit to quickly add another" do
    @driver.get($frontend)

    now = "#{$$}.#{Time.now.to_i}"

    @driver.find_element(:link => 'Create').click
    @driver.click_and_wait_until_gone(:link => 'Subject')

    @driver.clear_and_send_keys([:id, "subject_terms__0__term_"], "My First New Term #{now}")
    @driver.find_element(:id => "subject_source_").select_option("local")
    @driver.find_element(:css => "form #createPlusOne").click

    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Subject Created/)
    @driver.find_element(:id, "subject_terms__0__term_").attribute("value").should eq("")
  end
  
  it "can export a csv of browse list Subjects" do
    run_index_round

    @driver.find_element(:link => 'Browse').click
    @driver.click_and_wait_until_gone(:link => 'Subjects')

    el = @driver.find_element(:link => "Download CSV")
    @driver.download_file( el )
    sleep(1)
    assert(5) { Dir.glob(File.join( Dir.tmpdir,"*.csv" )).length.should eq(1) } 
    assert(5) { IO.read( Dir.glob(File.join( Dir.tmpdir,"*.csv" )).first ).include?(@repo.name)  }  
    assert(5) { IO.read( Dir.glob(File.join( Dir.tmpdir,"*.csv" )).first ).include?("just a term really")  }  
  
  end

end
