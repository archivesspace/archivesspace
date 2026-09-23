require 'spec_helper'

describe 'Bulk Archival Object Updater job', :skip_db_open do
  let(:job) do
    json = build(:json_job,
                 job_type: 'bulk_archival_object_updater_job',
                 job: build(:json_bulk_archival_object_updater_job))

    job = Job.create_from_json(json,
                               repo_id: $repo_id,
                               user: User[:username => 'admin'])

    spreadsheet = ASUtils.tempfile('bulk-archival-object-updater-job')
    spreadsheet.write('spreadsheet placeholder')
    spreadsheet.rewind
    job.add_file(spreadsheet)
    spreadsheet.close

    job.start!
    job
  end

  around do |example|
    as_test_user('admin') do
      RequestContext.open(:repo_id => $repo_id, :current_username => 'admin') do
        begin
          example.run
        ensure
          job.reload.destroy
        end
      end
    end
  end

  it 'saves completion and result metadata after the watchdog observes cancelation' do
    queue = BackgroundJobQueue.new
    allow(queue).to receive(:get_next_job).and_return(job)

    updater = instance_double(BulkArchivalObjectUpdater, info_messages: [])
    job_canceled = nil
    allow(BulkArchivalObjectUpdater).to receive(:new) do |filename, parameters, canceled|
      job_canceled = canceled
      updater
    end

    updated_uris = ["/repositories/#{$repo_id}/archival_objects/1"]
    allow(updater).to receive(:run) do
      Job.any_repo[job.id].cancel!

      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 15
      until job_canceled.value
        raise 'Watchdog did not signal cancelation' if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep(0.05)
      end

      # Simulate work completing after its last cancelation checkpoint.
      { updated_uris: updated_uris }
    end

    queue.run_pending_job

    completed_job = Job.any_repo[job.id]
    expect(completed_job.status).to eq('completed')
    expect(ASUtils.json_parse(completed_job.job_blob)).to eq('updated_uris' => updated_uris)
    expect(completed_job.created_records.map(&:record_uri)).to eq(updated_uris)
    expect(completed_job.job_files).to be_empty
  end
end
