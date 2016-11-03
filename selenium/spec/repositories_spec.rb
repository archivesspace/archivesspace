require_relative 'spec_helper'

describe "Repositories" do

  before(:all) do
    @test_repo_code_1 = "test1#{Time.now.to_i}_#{$$}"
    @test_repo_name_1 = "test repository 1 - #{Time.now.utc}"
    @test_repo_code_2 = "test2#{Time.now.to_i}_#{$$}"
    @test_repo_name_2 = "test repository 2 - #{Time.now.utc}"

    @driver = Driver.get.login($admin)
  end

  after(:all) do
    @driver.quit
  end


  it "flags errors when creating a repository with missing fields" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Repositories").click
    @driver.find_element(:link, "Create Repository").click
    @driver.clear_and_send_keys([:id, "repository_repository__name_"], "missing repo code")
    @driver.find_element(:css => "form#new_repository button[type='submit']").click

    assert(5) { @driver.find_element(:css => "div.alert.alert-danger").text.should eq('Repository Short Name - Property is required but was missing') }
  end


  it "can create a repository" do
    @driver.clear_and_send_keys([:id, "repository_repository__repo_code_"], @test_repo_code_1)
    @driver.clear_and_send_keys([:id, "repository_repository__name_"], @test_repo_name_1)
    @driver.find_element(:css => "form#new_repository button[type='submit']").click
  end

  it "can add telephone numbers" do
    @driver.find_element(:link, 'Edit').click
    
    @driver.find_element_with_text('//button', /Add Telephone Number/).click
    
    @driver.clear_and_send_keys([:id, "repository_agent_representation__agent_contacts__0__telephones__0__number_"], "555-5555")
    @driver.clear_and_send_keys([:id, "repository_agent_representation__agent_contacts__0__telephones__0__ext_"], "66")
    
    @driver.find_element_with_text('//button', /Add Telephone Number/).click

    @driver.clear_and_send_keys([:id, "repository_agent_representation__agent_contacts__0__telephones__1__number_"], "999-9999")

    @driver.click_and_wait_until_gone(:css => "form .record-pane button[type='submit']")
    @driver.find_element_with_text('//div[contains(@class, "alert-success")]', /Repository Saved/)
   
    assert(5) { @driver.find_element(:id => "repository_agent_representation__agent_contacts__0__telephones__0_").text.should
                                                          match(/555\-5555/) 
    }
    
    assert(5) { @driver.find_element(:id => "repository_agent_representation__agent_contacts__0__telephones__0_").text.should
                                                          match(/66/) 
    }
    
    assert(5) { @driver.find_element(:id => "repository_agent_representation__agent_contacts__0__telephones__1_").text.should
                                                          match(/999\-9999/) 
    }

  end

  it "Cannot delete the currently selected repository" do
    run_index_round
    @driver.select_repo(@test_repo_code_1)
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Repositories").click
    row = @driver.find_paginated_element(:xpath => "//tr[.//*[contains(text(), 'Selected')]]")
    row.find_element(:link, 'Edit').click
    @driver.ensure_no_such_element(:css, "button.delete-record")
  end

  it "Can delete a repository" do
    @deletable_repo = create(:repo, :repo_code => "deleteme_#{Time.now.to_i}")

    set_repo(@deletable_repo)

    5.times do
      create(:accession)
      create(:resource)
    end

    run_all_indexers

    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Repositories").click
    row = @driver.find_paginated_element(:xpath => "//tr[.//*[contains(text(), '#{@deletable_repo.repo_code}')]]")
    row.find_element(:link, 'Edit').click

    @driver.find_element(:css, ".delete-record.btn").click
    @driver.clear_and_send_keys([:id, 'deleteRepoConfim'], @deletable_repo.repo_code )
    @driver.wait_for_ajax

    @driver.find_element(:css, "#confirmChangesModal #confirmButton").click
    assert(5) { @driver.find_element(:css => "div.alert.alert-success").text.should eq("Repository Deleted") }
  end


  it "can create a second repository" do
    @driver.find_element(:link, 'System').click
    @driver.find_element(:link, "Manage Repositories").click
    @driver.find_element(:link, "Create Repository").click
    @driver.clear_and_send_keys([:id, "repository_repository__repo_code_"], @test_repo_code_2)
    @driver.clear_and_send_keys([:id, "repository_repository__name_"], @test_repo_name_2)
    @driver.find_element(:css => "form#new_repository button[type='submit']").click
  end


  it "can select either of the created repositories" do
    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository').find_element(:id => "id").select_option_with_text(@test_repo_code_2)
    @driver.find_element(:css, '.select-a-repository .btn-primary').click
    assert(5) { @driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }

    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository select').find_element(:id => "id").select_option_with_text(@test_repo_code_1)
    @driver.find_element(:css, '.select-a-repository .btn-primary').click
    assert(5) { @driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_1 }

    @driver.find_element(:link, 'Select Repository').click
    @driver.find_element(:css, '.select-a-repository select').find_element(:id => "id").select_option_with_text(@test_repo_code_2)
    @driver.find_element(:css, '.select-a-repository .btn-primary').click
    assert(5) { @driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }
  end

  it "will persist repository selection" do
    assert(5) { @driver.find_element(:css, 'span.current-repository-id').text.should eq @test_repo_code_2 }
  end

  it "automatically refreshes the repository list when a new repo gets added" do
    repo = create(:repo)

    assert(5) { 
      @driver.navigate.refresh
      @driver.find_element(:link, 'Select Repository').click
      @driver.find_element(:css, '.select-a-repository').select_option_with_text(repo.repo_code) 
    }
  end
end
