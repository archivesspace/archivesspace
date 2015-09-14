require_relative 'spec_helper'

describe "User Preferences" do

  before(:all) do
    @repo = create(:repo, :repo_code => "user_pref_test_#{Time.now.to_i}")
    set_repo(@repo)

    @accession = create(:accession, :title => "a browseable accession")

    run_all_indexers

    @driver = Driver.new
    @driver.login_to_repo($admin, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "allows you to configure browse columns" do
    2.times {
      @driver.find_element(:css, '.user-container .btn.dropdown-toggle.last').click
      @driver.find_element(:link, "My Repository Preferences").click

      @driver.find_element(:id => "preference_defaults__accession_browse_column_1_").select_option_with_text("Acquisition Type")
      @driver.find_element(:css => 'button[type="submit"]').click
      @driver.find_element(:css => ".alert-success")
    }

    @driver.find_element(:link => 'Browse').click
    @driver.find_element(:link => 'Accessions').click
    @driver.find_element(:link => "Create Accession")

    cells = @driver.find_elements(:css, "table th")
    cells[1].text.should eq("Title")
    cells[2].text.should eq("Acquisition Type")
  end
end
