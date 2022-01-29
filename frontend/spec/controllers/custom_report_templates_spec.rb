require 'spec_helper'
require 'rails_helper'

describe CustomReportTemplatesController, type: :controller do

  before(:each) do
    set_repo($repo)
  end

  it "creates a data object from request parameters" do
    session = User.login('admin', 'admin')
    User.establish_session(controller, session, 'admin')
    controller.session[:repo_id] = JSONModel.repository

    form_params = {
      custom_report_template: {
        name: "my custom report template #{Time.now.to_i}",
        limit: 10,
        data: {
          custom_record_type: 'my_custom_type',
          my_custom_type: {
            fields: {
              field_1: {
                include: 1,
                values: ["value1.1", "value1.2"]
              }
            }
          }
        }
      }
    }

    post :create, params: form_params
    data = JSON.parse(JSONModel(:custom_report_template).all(page: 1)["results"][0].data)
    expect(data["fields"]["field_1"]["values"]).to eq(["value1.1", "value1.2"])
  end
end
