require 'spec_helper'

describe 'Permissions controller' do

  it "gives a list of all permissions at a given level" do
    Permission.define("new_permission",
                      "A new test permission",
                      :level => "repository")

    repository_permissions = JSONModel(:permission).all(:level => "repository")
    all_permissions = JSONModel(:permission).all(:level => "all")

    repo_permissions = {}
    repository_permissions.each do |permission|
      permission.level.should eq('repository')
      repo_permissions[permission.permission_code] = true
    end

    repository_permissions.any? {|permission| permission.permission_code == "new_permission"}.should == true

    (Set.new(all_permissions) - Set.new(repository_permissions)).all? {|permission|
      if not repo_permissions[permission.permission_code]
        permission.level.should eq('global')
      end
    }
  end


  it "throws an error if you don't specify a level correctly" do
    expect { JSONModel(:permission).all }.to raise_error(RuntimeError)
    expect { JSONModel(:permission).all(:level => "somethinginvalid") }.to raise_error(RuntimeError)
  end

end
