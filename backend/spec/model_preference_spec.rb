require 'spec_helper'

describe 'Preference model' do

  before(:all) do
    @pref = {
      'color' => 'red',
      'length' => 1,
      'happy' => true,
    }
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


  it "doesn't mind if no preference records exist" do
    Preference.global_defaults.should eq({})    
    Preference.user_global_defaults.should eq({})    
    Preference.repo_defaults.should eq({})    
    Preference.defaults.should eq({})    
  end

  it "supports creating a new preference" do
    pref = Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@pref)))
    ASUtils.json_parse(Preference[pref[:id]].defaults)['color'].should eq(@pref['color'])
  end

  it "can give the global defaults" do
    RequestContext.open(:repo_id => Repository.global_repo_id) do
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)))
    end
    Preference.global_defaults['color'].should eq(@glob_pref['color'])    
  end

  it "ensures there is only one preference record for each combination of repo and user" do
    repo_id = make_test_repo("REPO")
    user = create(:user, :username => 'somebody')

    RequestContext.open(:repo_id => Repository.global_repo_id) do
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)))
      expect {
        Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)))
      }.to raise_error

      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)),
                                  :user_id => user.id)
      expect {
        Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)),
                                    :user_id => user.id)
      }.to raise_error
    end

    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)))
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)))
    }.to raise_error

    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)),
                                :user_id => user.id)
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)),
                                  :user_id => user.id)
    }.to raise_error
  end


  it "merges defaults for a repository and user" do
    user_id = User[:username => RequestContext.get(:current_username)].id

    RequestContext.open(:repo_id => Repository.global_repo_id) do
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_pref)))
      Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@glob_user_pref)),
                                  :user_id => user_id)
    end
    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_pref)))
    Preference.create_from_json(build(:json_preference, :defaults => JSON.generate(@repo_user_pref)),
                                :user_id => user_id)

    Preference.global_defaults['color'].should eq(@glob_pref['color'])
    Preference.user_global_defaults['color'].should eq(@glob_user_pref['color'])
    Preference.repo_defaults['length'].should eq(@repo_pref['length'])
    Preference.defaults['happy'].should eq(@repo_user_pref['happy'])
  end

end
