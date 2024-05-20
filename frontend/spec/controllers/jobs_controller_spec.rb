# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe JobsController, type: :controller do
  render_views

  let(:unmod_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "report_job", status: "completed", time_submitted: "2021-10-01 07:09:44 UTC", time_started: "2021-10-01 07:09:44 UTC", time_finished: "2021-10-01 07:09:44 UTC", repository: {ref: "/repositories/1", _resolved: {repo_code: "foobar"}}}) }
  let(:mod_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "report_job", status: "completed", time_submitted: "2021-10-01 07:09:44 UTC", time_started: "2021-10-01 07:09:44 UTC", time_finished: "2021-10-01 07:09:44 UTC", repository: {ref: "/repositories/1", _resolved: {repo_code: "foobar"}}, has_modified_records: true}) }

  it "only shows modified records section if there are modified records" do
    allow(controller).to receive(:user_must_have).and_return(true)

    allow(JSONModel::HTTP).to receive(:get_json).and_call_original
    allow(JSONModel::HTTP).to receive(:get_json).with(/output_files/).and_return([1, 2, 3])
    allow(JSONModel::HTTP).to receive(:get_json).with("/job_types").and_return({report_job: {cancel_permissions: [], create_permissions: []}})
    allow(JSONModel::HTTP).to receive(:get_json).with("/notifications").and_call_original

    allow(JSONModel(:job)).to receive(:find).with("1", "resolve[]" => "repository").and_return(mod_job)
    allow(mod_job).to receive(:id).and_return 1
    allow(mod_job).to receive(:job).and_return({'jsonmodel_type' => "report_job"})

    get :show, params: {id: 1}
    expect(response.body).to have_text "New & Modified Records"

    allow(JSONModel(:job)).to receive(:find).with("2", "resolve[]" => "repository").and_return(unmod_job)
    allow(unmod_job).to receive(:id).and_return 2
    allow(unmod_job).to receive(:job).and_return({'jsonmodel_type' => "report_job"})

    get :show, params: {id: 2}
    expect(response.body).not_to have_text "New & Modified Records"
  end
end
