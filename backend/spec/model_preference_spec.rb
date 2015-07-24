require 'spec_helper'

describe 'Preference model' do

  before(:all) do
    @original_defaults_model = JSONModel.models["defaults"].schema
    JSONModel.destroy_model(:defaults)

    JSONModel.create_model_for("defaults",
                               {
                                 "$schema" => "http://www.archivesspace.org/archivesspace.json",
                                 "version" => 1,
                                 "type" => "object",
                                 "properties" => {
                                   "color" =>  {"type" => "string", "maxlength" => 255, "required" => false},
                                   "length" =>  {"type" => "integer", "required" => false},
                                   "happy" =>  {"type" => "boolean", "required" => false},
                                   "show_suppressed" =>  {"type" => "boolean", "required" => false},
                                 },
                               })

    @pref = {
      'color' => 'red',
      'length' => 1,
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

  after(:all) do
    JSONModel.destroy_model(:defaults)
    JSONModel.create_model_for("defaults", @original_defaults_model)
  end


  it "supports creating a new preference" do
    pref = Preference.create_from_json(build(:json_preference, :defaults => @pref))
    ASUtils.json_parse(Preference[pref[:id]].defaults)['color'].should eq(@pref['color'])
  end


  it "ensures there is only one preference record for each combination of repo and user" do
    repo_id = make_test_repo("REPO")
    user = create(:user, :username => 'somebody')

    RequestContext.open(:repo_id => Repository.global_repo_id) do

      expect {
        Preference.create_from_json(build(:json_preference))
      }.to raise_error(Sequel::UniqueConstraintViolation)

      Preference.create_from_json(build(:json_preference, :defaults => @glob_user_pref),
                                  :user_id => user.id)
      expect {
        Preference.create_from_json(build(:json_preference, :defaults => @glob_user_pref),
                                    :user_id => user.id)
      }.to raise_error(Sequel::UniqueConstraintViolation)
    end

    Preference.create_from_json(build(:json_preference, :defaults => @repo_pref))
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => @repo_pref))
    }.to raise_error(Sequel::UniqueConstraintViolation)

    Preference.create_from_json(build(:json_preference, :defaults => @repo_user_pref),
                                :user_id => user.id)
    expect {
      Preference.create_from_json(build(:json_preference, :defaults => @repo_user_pref),
                                  :user_id => user.id)
    }.to raise_error(Sequel::UniqueConstraintViolation)
  end


  it "merges defaults for a repository and user" do
    user_id = User[:username => RequestContext.get(:current_username)].id

    RequestContext.open(:repo_id => Repository.global_repo_id) do
#      Preference.create_from_json(build(:json_preference, :defaults => @glob_pref))
      Preference.create_from_json(build(:json_preference, :defaults => @glob_user_pref),
                                  :user_id => user_id)
    end
    Preference.create_from_json(build(:json_preference, :defaults => @repo_pref))
    Preference.create_from_json(build(:json_preference, :defaults => @repo_user_pref),
                                :user_id => user_id)

#    Preference.global_defaults['color'].should eq(@glob_pref['color'])
    Preference.user_global_defaults['color'].should eq(@glob_user_pref['color'])
    Preference.repo_defaults['length'].should eq(@repo_pref['length'])
    Preference.defaults['happy'].should eq(@repo_user_pref['happy'])
  end

end
