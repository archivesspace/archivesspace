require 'spec_helper'

describe 'custom report template controller' do

  it "restricts access" do
    group = create(:json_group)

    create(:user, {:username => 'intern'})
    create(:user, {:username => 'manager'})

    group.member_usernames = ['manager']
    group.grants_permissions = ['manage_custom_report_templates']
    group.save

    expect {
      as_test_user("manager") do
        create(:json_custom_report_template)
      end
    }.not_to raise_error

    expect {
      as_test_user("intern") do
        create(:json_custom_report_template)
      end
    }.to raise_error AccessDeniedException
  end
end
