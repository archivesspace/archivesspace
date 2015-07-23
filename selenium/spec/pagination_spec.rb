require_relative 'spec_helper'


describe "Pagination" do

  before(:all) do
    login_as_repo_manager
  end


  after(:all) do
    logout
    $accession_url = nil
  end


  it "can navigate through pages of accessions" do
    c = 0
    (AppConfig[:default_page_size].to_i * 2 + 1).times do
      create_accession(:title => "acc #{c += 1}")
    end
    run_index_round

    $driver.find_element(:link, "Browse").click
    $driver.find_element(:link, "Accessions").click
    expect {
      $driver.find_element_with_text('//div', /Showing 1 - #{AppConfig[:default_page_size]}/)
    }.to_not raise_error

    $driver.find_element(:xpath, '//a[@title="Next"]').click
    expect {
      $driver.find_element_with_text('//div', /Showing #{AppConfig[:default_page_size] + 1}/)
    }.to_not raise_error

  end

  it "can navigate through pages of digital objects " do
    c = 0
    (AppConfig[:default_page_size].to_i + 1).times do
      create_digital_object({ :title => "I can't believe this is DO number #{c += 1}"})
    end
    run_index_round

    $driver.find_element(:link, "Browse").click
    $driver.find_element(:link, "Digital Objects").click
    expect {
      $driver.find_element_with_text('//div', /Showing 1 - #{AppConfig[:default_page_size]}/)
    }.to_not raise_error

    $driver.find_element(:xpath, '//a[@title="Next"]').click
    expect {
      $driver.find_element_with_text('//div', /Showing #{AppConfig[:default_page_size] + 1}/)
    }.to_not raise_error

  end
end
