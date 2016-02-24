require 'spec_helper'

describe 'job model and job runners' do

  before(:all) do
    enum = Enumeration.find(:name => 'job_type')
    EnumerationValue.create(:value => 'nugatory_job', :enumeration_id => enum.id)

    BackendEnumSource.cache_entry_for('job_type', true)

    JSONModel(:job).schema['properties']['job']['type'] = 'object'


    class NugatoryJobRunner < JobRunner

      @run_till_canceled = false


      def initialize(job)
        @job = job
      end

      def self.run_till_canceled!
        @run_till_canceled = true
      end

      def self.run_till_canceled?
        @run_till_canceled
      end

      def self.reset
        @run_till_canceled = false
      end


      def self.instance_for(job)
        if job.job_type == "nugatory_job"
          self.new(job)
        else
          nil
        end
      end


      def run
        while self.class.run_till_canceled?
          break if @job_canceled && @job_canceled.value
          sleep(0.2)
        end
      end

    end
  end

  after(:all) do
    RequestContext.open(:repo_id => $repo_id) do
      as_test_user("admin") do
        EnumerationValue.filter(:value => 'nugatory_job').first.destroy
        BackendEnumSource.cache_entry_for('job_type', true)
      end
    end
  end


  after(:each) do
    NugatoryJobRunner.reset
  end


  describe "Job and JobRunner" do

    let(:job) {
      user = create_nobody_user


      json = JSONModel(:job).from_hash({
                                         :job_type => 'nugatory_job',
                                         :job => {},
                                       })


      Job.create_from_json(json,
                           :repo_id => $repo_id,
                           :user => user)
    }

    it 'can get the status of a job' do
      job.status.should eq('queued')
    end

    it "can get the owner of a job" do
      job.owner.username.should eq("nobody")
    end


    it "can record created URIs for a job" do
      job.record_created_uris((1..10).map {|n| "/repositories/#{$repo_id}/accessions/#{n}"})

      job.created_records.count.should eq(10)
    end


    it "can record modified URIs for a job" do
      job.record_modified_uris((1..10).map {|n| "/repositories/#{$repo_id}/accessions/#{n}"})

      job.modified_records.count.should eq(10)
    end


    it "can attach some input files to a job" do

      allow(job).to receive(:file_store) do
        double(:store => "stored_path")
      end

      job.add_file(StringIO.new)
      job.add_file(StringIO.new)

      job.job_files.map(&:file_path).should eq(["stored_path", "stored_path"])
    end


    it 'can get the right runner for the job' do
      JobRunner.for(job).class.to_s.should eq('NugatoryJobRunner')
    end


    it 'runs a job and keeps track of its canceled state' do
      runner = JobRunner.for(job).canceled(Atomic.new(false))
      runner.run
      runner.instance_variable_get(:@job_canceled).value.should == false
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
                                       :job_type => 'nugatory_job',
                                       :job => {},
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
      @job.status.should eq('queued')

      q.run_pending_job

      sleep(0.5)

      Job.any_repo[job_id].status.should eq('completed')
    end


    it "can stop a canceled job and finish it", :skip_db_open do
      NugatoryJobRunner.run_till_canceled!

      json = JSONModel(:job).from_hash({
                                       :job_type => 'nugatory_job',
                                       :job => {},
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
      @job.status.should eq('queued')

      cancel_thread = Thread.new do
        sleep(0.5)
        @job.reload
        @job.cancel!
      end

      q.run_pending_job

      cancel_thread.join

      job = Job.any_repo[job_id]

      job.status.should eq('canceled')
      job.time_finished.should_not be_nil
      job.time_finished.should < Time.now
    end

  end
end
