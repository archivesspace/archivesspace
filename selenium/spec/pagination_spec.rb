require_relative 'spec_helper'


describe "Pagination" do

  before(:all) do
    @repo = create(:repo, :repo_code => "pagination_test_#{Time.now.to_i}")
    set_repo @repo

    c = 0
    (AppConfig[:default_page_size].to_i * 2 + 1).times do
      create(:accession,
             :title => "acc #{c += 1}")
      create(:digital_object,
             :title => "I can't believe this is DO number #{c += 1}")
    end
    run_index_round

    @manager = create_user(@repo => ['repository-managers'])

    @driver = Driver.get.login_to_repo(@manager, @repo)
  end


  after(:all) do
    @driver.quit
  end


  it "can navigate through pages of accessions" do
    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Accessions")
    expect {
      @driver.find_element_with_text('//div', /Showing 1 - #{AppConfig[:default_page_size]}/)
    }.to_not raise_error

    @driver.click_and_wait_until_gone(:xpath, '//a[@title="Next"]')
    expect {
      @driver.find_element_with_text('//div', /Showing #{AppConfig[:default_page_size] + 1}/)
    }.to_not raise_error
  end

  it "can navigate through pages of digital objects " do
    @driver.find_element(:link, "Browse").click
    @driver.click_and_wait_until_gone(:link, "Digital Objects")
    expect {
      @driver.find_element_with_text('//div', /Showing 1 - #{AppConfig[:default_page_size]}/)
    }.to_not raise_error

    @driver.click_and_wait_until_gone(:xpath, '//a[@title="Next"]')
    expect {
      @driver.find_element_with_text('//div', /Showing #{AppConfig[:default_page_size] + 1}/)
    }.to_not raise_error

  end
end
