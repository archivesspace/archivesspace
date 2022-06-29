# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe DateCalculatorController, type: :controller do
  render_views

  before(:each) do
    set_repo($repo)
  end

  it "manages 4 digit years in params" do
    allow(controller).to receive(:user_must_have).and_return(true)
    resource = create(:json_resource)
    allow(JSONModel(:resource)).to receive(:find).and_return(resource)

    params = { "record_uri" => resource.uri,
               "record_type" => "resource",
               "record_id" => resource.id, "date"=>{"lock_version"=>"", "label"=>"creation", "expression"=>"", "date_type"=>"inclusive", "begin"=>"1900", "end"=>"1901", "certainty"=>"", "era"=>"", "calendar"=>""}
             }

    user = build(:json_user).save(password: "saa2020")
    user = User.find(user)
    group = create(:json_group,
                   member_usernames: [user.username],
                   grants_permissions: ["view_repository", "update_resource_record", "delete_event_record"])
    session = User.login(user.username, "saa2020")
    User.establish_session(controller, session, user.username)
    controller.send(:load_repository_list)
    post :create_date, params: params
    expect(response.status).to eq(200)
  end
end
