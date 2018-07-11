require_relative 'spec_helper'
require_relative '../app/lib/index_state'

describe "index state" do
  before(:each) do
    FileUtils.remove_dir("#{AppConfig[:data_directory]}" + "/indexer_state", true)
    state_class = AppConfig[:index_state_class].constantize
    @state = state_class.new
  end
  describe "initialize" do
    it "initializes index state directory using data_directory from AppConfig and '/indexer_state'" do
      s_dir = "#{AppConfig[:data_directory]}" + "/indexer_state"
      expect(@state.instance_variable_get(:@state_dir)).to eq(s_dir)
    end
    # it "initializes index state directory using data_directory from AppConfig and '/indexer_pui_state'" do
    #   s_dir = "#{AppConfig[:data_directory]}" + "/indexer_pui_state"
    #   expect(@state.instance_variable_get(:@state_dir)).to eq(s_dir)
    # end
  end
  describe "path_for" do
    it "provides the path for indexer_state file using repository_id and record_type" do
      repo_id = 2
      rec_type = 'resource'
      s_dir = "#{AppConfig[:data_directory]}" + "/indexer_state" + "/#{repo_id}" + "_#{rec_type}"
      expect(@state.path_for(repo_id,rec_type)).to eq(s_dir)
    end
    it "creates directory for indexer_state files" do
      repo_id = 2
      rec_type = 'resource'
      @state.path_for(repo_id,rec_type)
      s_dir = "#{AppConfig[:data_directory]}" + "/indexer_state"
      expect(File.directory?(s_dir)).to be true
    end
  end
  describe "set_last_mtime" do
    it "sets last mtime" do
      start = Time.now
      repo_id = 3
      rec_type = 'accession'
      @state.set_last_mtime(repo_id, rec_type, start)
      path = @state.path_for(repo_id,rec_type)
      expect(File.mtime("#{path}.dat").utc).to be_within(1).of(start.utc)
    end
  end
  describe "get_last_mtime" do
    it "gets last mtime" do
      start = Time.now
      repo_id = 4
      rec_type = 'archival_object'
      @state.set_last_mtime(repo_id, rec_type, start)
      expect(@state.get_last_mtime(repo_id, rec_type)).to be_within(1).of(start.to_i)
    end
    it "returns 0 for mtime if have not indexed this repository and record_type pair" do
      start = Time.now
      repo_id = 5
      rec_type = 'digital_object'
      expect(@state.get_last_mtime(repo_id, rec_type)).to eq(0)
    end
  end
end
