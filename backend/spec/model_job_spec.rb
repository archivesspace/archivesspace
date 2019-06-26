require 'spec_helper'

describe 'Background jobs' do

  before(:all) do

    JSONModel.create_model_for("nugatory_job",
                               {
                                 "$schema" => "http://www.archivesspace.org/archivesspace.json",
                                 "version" => 1,
                                 "type" => "object",
                                 "properties" => {}
                               })


    class NugatoryJobRunner < JobRunner
      register_for_job_type("nugatory_job")

      @run_till_canceled = false

      def self.run_till_canceled!
        @run_till_canceled = true
      end

      def self.run_till_canceled?
        @run_till_canceled
      end

      def self.reset
        @run_till_canceled = false
      end

      def run
        while self.class.run_till_canceled?
          break if self.canceled?
          sleep(0.2)
        end
      end
    end


    class HiddenJobRunner < JobRunner
      register_for_job_type("hidden_job", :hidden => true)
    end

    class ConcurrentJobRunner < JobRunner
      register_for_job_type("concurrent_job", :run_concurrently => true)
    end

    class PermissionJobRunner < JobRunner
      register_for_job_type("permissions_job",
                            :create_permissions => 'god_like',
                            :cancel_permissions => ['death', 'destruction'])
    end
  end


  after(:all) do
    JSONModel.destroy_model(:nugatory_job)
  end


  after(:each) do
    NugatoryJobRunner.reset
  end


  describe "Job and JobRunner" do

    let(:job) {
      user = create_nobody_user
      json = JSONModel(:job).from_hash({:job => {'jsonmodel_type' => 'nugatory_job'}})
      Job.create_from_json(json, :repo_id => $repo_id, :user => user)
    }


    it 'can get the status of a job' do
      expect(job.status).to eq('queued')
    end


    it "can get the owner of a job" do
      expect(job.owner.username).to eq("nobody")
    end


    it "can record created URIs for a job" do
      job.record_created_uris((1..10).map {|n| "/repositories/#{$repo_id}/accessions/#{n}"})
      expect(job.created_records.count).to eq(10)
    end


    it "can record modified URIs for a job" do
      job.record_modified_uris((1..10).map {|n| "/repositories/#{$repo_id}/accessions/#{n}"})
      expect(job.modified_records.count).to eq(10)
    end


    it "can attach some input files to a job" do
      allow(job).to receive(:file_store) do
        double(:store => "stored_path")
      end

      job.add_file(StringIO.new)
      job.add_file(StringIO.new)

      expect(job.job_files.map(&:file_path)).to eq(["stored_path", "stored_path"])
    end


    it 'can get the right runner for the job' do
      expect(JobRunner.for(job).class).to eq(NugatoryJobRunner)
    end


    it 'ensures only one runner can register for a job type' do
      expect {
        JobRunner.register_for_job_type('nugatory_job')
      }.to raise_error(JobRunner::JobRunnerError)
    end


    it 'can give you the registered runner for a job type' do
      runner = JobRunner.registered_runner_for('nugatory_job')
      expect(runner.type).to eq('nugatory_job')
    end


    it 'knows if a job type allows concurrency' do
      expect(JobRunner.registered_runner_for('nugatory_job').run_concurrently).to be_falsey
      expect(JobRunner.registered_runner_for('concurrent_job').run_concurrently).to be_truthy
    end


    it 'knows the permissions required to create or cancel a job' do
      runner = JobRunner.registered_runner_for('nugatory_job')
      expect(runner.create_permissions).to eq []
      expect(runner.cancel_permissions).to eq []

      runner = JobRunner.registered_runner_for('permissions_job')
      expect(runner.create_permissions).to eq ['god_like']
      expect(runner.cancel_permissions).to eq ['death', 'destruction']
    end


    it 'can give you a list of registered job types and their permissions' do
      types = JobRunner.registered_job_types
      expect(types['nugatory_job'][:create_permissions]).to eq []
    end


    it 'will not tell you about hidden job types' do
      types = JobRunner.registered_job_types
      expect(types['hidden_job']).to be_nil
    end


    it 'will give you the registered runner for a hidden job type' do
      runner = JobRunner.registered_runner_for('hidden_job')
      expect(runner.type).to eq('hidden_job')
    end


    it 'runs a job and keeps track of its canceled state' do
      runner = JobRunner.for(job)
      runner.cancelation_signaler(Atomic.new(false))
      runner.run
      expect(runner.canceled?).to be_falsey
    end
  end


  describe "BackgroundJobQueue" do

    let(:q) {
      q = BackgroundJobQueue.new
    }


    before(:each) do
      @job = nil
    end


    after(:each) do
      as_test_user("admin") do
        RequestContext.open(:repo_id => $repo_id) do
          RequestContext.put(:current_username, "admin")

          @job.destroy
          User.filter(:username => 'jobber').first.destroy
        end
      end
    end


    it "can find the next queued job and start it", :skip_db_open do
      json = JSONModel(:job).from_hash({
                                       :job => {'jsonmodel_type' => 'nugatory_job'},
                                       })

      as_test_user("admin") do
        RequestContext.open do
          RequestContext.put(:repo_id, $repo_id)
          RequestContext.put(:current_username, "admin")
          user = create(:user, :username => 'jobber')
          @job = Job.create_from_json(json,
                                      :repo_id => $repo_id,
                                      :user => user)
        end
      end

      job_id = @job.id
      expect(@job.status).to eq('queued')

      q.run_pending_job

      sleep(0.5)

      expect(Job.any_repo[job_id].status).to eq('completed')
    end


    it "can stop a canceled job and finish it", :skip_db_open do
      NugatoryJobRunner.run_till_canceled!

      json = JSONModel(:job).from_hash({:job => {'jsonmodel_type' => 'nugatory_job'}})

      as_test_user("admin") do
        RequestContext.open do
          RequestContext.put(:repo_id, $repo_id)
          RequestContext.put(:current_username, "admin")
          user = create(:user, :username => 'jobber')

          @job = Job.create_from_json(json,
                                      :repo_id => $repo_id,
                                      :user => user)
        end
      end

      job_id = @job.id
      expect(@job.status).to eq('queued')

      cancel_thread = Thread.new do
        sleep(0.5)
        @job.reload
        @job.cancel!
      end

      q.run_pending_job

      cancel_thread.join

      job = Job.any_repo[job_id]

      expect(job.status).to eq('canceled')
      expect(job.time_finished).not_to be_nil
      expect(job.time_finished).to be < Time.now
    end
  end
end
