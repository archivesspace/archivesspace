# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe JobsController, type: :controller do
  render_views

  let(:unmod_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "report_job", status: "completed", time_submitted: "2021-10-01 07:09:44 UTC", time_started: "2021-10-01 07:09:44 UTC", time_finished: "2021-10-01 07:09:44 UTC", repository: {ref: "/repositories/1", _resolved: {repo_code: "foobar"}}}) }
  let(:mod_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "report_job", status: "completed", time_submitted: "2021-10-01 07:09:44 UTC", time_started: "2021-10-01 07:09:44 UTC", time_finished: "2021-10-01 07:09:44 UTC", repository: {ref: "/repositories/1", _resolved: {repo_code: "foobar"}}, has_modified_records: true}) }

  describe '#show' do
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

  describe '#download_file_format' do
    let(:report_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "report_job"}) }
    let(:top_container_linker_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "top_container_linker_job"}) }
    let(:import_job) { JSONModel(:job).from_hash({uri: "/jobs/1", job_type: "import_job"}) }

    it 'returns format from params[:ext] when provided' do
      allow(controller).to receive(:params).and_return({ ext: '.csv' })
      allow(report_job).to receive(:job).and_return({ "format" => "pdf" })
      controller.instance_variable_set(:@job, report_job)

      result = controller.send(:download_file_format, report_job)

      expect(result).to eq("csv")
    end

    it 'returns format from job.format for report jobs' do
      allow(controller).to receive(:params).and_return({})
      allow(report_job).to receive(:job).and_return({ "format" => "html" })
      controller.instance_variable_set(:@job, report_job)

      result = controller.send(:download_file_format, report_job)

      expect(result).to eq("html")
    end

    it 'returns format from job.content_type for top container linker jobs' do
      allow(controller).to receive(:params).and_return({})
      allow(top_container_linker_job).to receive(:job).and_return({ "content_type" => "xlsx" })
      controller.instance_variable_set(:@job, top_container_linker_job)

      result = controller.send(:download_file_format, top_container_linker_job)

      expect(result).to eq("xlsx")
    end

    it 'defaults to pdf when neither ext, format, nor content_type provided' do
      allow(controller).to receive(:params).and_return({})
      allow(import_job).to receive(:job).and_return({})
      controller.instance_variable_set(:@job, import_job)

      result = controller.send(:download_file_format, import_job)

      expect(result).to eq("pdf")
    end
  end
end
