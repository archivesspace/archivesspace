require 'spec_helper'

describe 'Preference model' do

  before(:all) do
    @glob_pref = {
      'color' => 'white',
      'length' => 3,
      'happy' => true,
    }
    @glob_user_pref = {
      'color' => 'black',
      'length' => 3,
      'happy' => true,
    }
    @repo_pref = {
      'color' => 'white',
      'length' => 12,
      'happy' => true,
    }
    @repo_user_pref = {
      'color' => 'white',
      'length' => 3,
      'happy' => false,
    }
  end


  it "supports creating a new preference" do
    pref = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)), :repo_id => 1)
    JSON.parse(Preference[pref[:id]].defaults)['color'].should eq(@glob_pref['color'])
  end


  it "merges defaults for a repository and user" do
#    puts "CCCCCCCCCCCCCC #{RequestContext.get(:current_username)}"
#    puts "CCCCCCCCCCCCCC #{RequestContext.get(:repo_id)}"
    repo_id = make_test_repo("REPO")
    user = create(:user, :username => 'somebody')

    glob = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)), :repo_id => 1)
    user_glob = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)), :repo_id => 1, :user_id => user.id)
    repo = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)), :repo_id => repo_id)
    user_repo = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)), :repo_id => repo_id, :user_id => user.id)

    JSON.parse(Preference.defaults_for())['color'].should eq(@glob_pref['color'])
    JSON.parse(Preference.defaults_for(1, 'somebody'))['color'].should eq(@glob_user_pref['color'])
    JSON.parse(Preference.defaults_for(repo_id))['length'].should eq(@repo_pref['length'])
    JSON.parse(Preference.defaults_for(repo_id, 'somebody'))['happy'].should eq(@repo_user_pref['happy'])

    JSON.parse(Preference.defaults)['color'].should eq(@repo_pref['color'])
    JSON.parse(Preference.defaults)['length'].should eq(@repo_pref['length'])
    JSON.parse(Preference.defaults)['happy'].should eq(@repo_pref['happy'])

  end

end
