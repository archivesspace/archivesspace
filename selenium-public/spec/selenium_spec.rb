require_relative 'spec_helper'
require_relative '../../indexer/periodic_indexer'

describe "ArchivesSpace Public interface" do

  # Start the dev servers and Selenium
  before(:all) do
    selenium_init
    state = Object.new.instance_eval do
      @store = {}

      def get_last_mtime(repo_id, record_type)
        @store[[repo_id, record_type]].to_i || 0
      end

      def set_last_mtime(repo_id, record_type, time)
        @store[[repo_id, record_type]] = time
      end

      self
    end

    @indexer = PeriodicIndexer.get_indexer(state)
  end


  before(:each) do
    $driver.navigate.to $public
  end


  # Stop selenium, kill the dev servers
  after(:all) do
    report_sleep
    cleanup
  end


  def self.xdescribe(*stuff)
  end

  after(:each) do |group|
    if group.example.exception and ENV['SCREENSHOT_ON_ERROR']
      outfile = "/tmp/#{Time.now.to_i}_#{$$}.png"
      puts "Saving screenshot to #{outfile}"
      $driver.save_screenshot(outfile)
    end
  end


  describe "Homepage" do

    it "is visible" do
      $driver.find_element_with_text('//h3', /Welcome to ArchivesSpace./)
    end

  end


  describe "Repositories" do

    before(:all) do
      @test_repo_code_1 = "test1#{Time.now.to_i}_#{$$}"
      @test_repo_name_1 = "test repository 1 - #{Time.now}"
      @test_repo_code_2 = "test2#{Time.now.to_i}_#{$$}"
      @test_repo_name_2 = "test repository 2 - #{Time.now}"

      create_test_repo(@test_repo_code_1, @test_repo_name_1)
      create_test_repo(@test_repo_code_2, @test_repo_name_2)
    end


    it "lists all available repositories" do
      $driver.find_element(:link, "Repositories").click

      $driver.find_element_with_text('//a', /#{$test_repo}/)
      $driver.find_element_with_text('//a', /#{@test_repo_code_1}/)
      $driver.find_element_with_text('//a', /#{@test_repo_code_2}/)
    end

  end

end
