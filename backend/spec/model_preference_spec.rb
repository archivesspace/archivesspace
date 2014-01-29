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
    pref = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)), :repo_id => Repository.global_repo_id)
    JSON.parse(Preference[pref[:id]].defaults)['color'].should eq(@glob_pref['color'])
  end


  it "ensures there is only one preference record for each combination of repo and user" do
    repo_id = make_test_repo("REPO")
    user = create(:user, :username => 'somebody')

    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)),
                                :repo_id => Repository.global_repo_id)
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)),
                                  :repo_id => Repository.global_repo_id)
    }.to raise_error

    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)),
                                :repo_id => Repository.global_repo_id, :user_id => user.id)
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)),
                                  :repo_id => Repository.global_repo_id, :user_id => user.id)
    }.to raise_error

    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)),
                                :repo_id => repo_id)
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)),
                                  :repo_id => repo_id)
    }.to raise_error

    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)),
                                :repo_id => repo_id, :user_id => user.id)
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)),
                                  :repo_id => repo_id, :user_id => user.id)
    }.to raise_error
  end


  it "merges defaults for a repository and user" do
    repo_id = make_test_repo("REPO")
    user = create(:user, :username => 'somebody')

    glob = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)),
                                       :repo_id => Repository.global_repo_id)
    user_glob = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)),
                                            :repo_id => Repository.global_repo_id, :user_id => user.id)
    repo = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)),
                                       :repo_id => repo_id)
    user_repo = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)),
                                            :repo_id => repo_id, :user_id => user.id)

    Preference.defaults_for()['color'].should eq(@glob_pref['color'])
    Preference.defaults_for(Repository.global_repo_id, 'somebody')['color'].should eq(@glob_user_pref['color'])
    Preference.defaults_for(repo_id)['length'].should eq(@repo_pref['length'])
    Preference.defaults_for(repo_id, 'somebody')['happy'].should eq(@repo_user_pref['happy'])

    Preference.defaults['color'].should eq(@repo_pref['color'])
    Preference.defaults['length'].should eq(@repo_pref['length'])
    Preference.defaults['happy'].should eq(@repo_pref['happy'])

  end

end
