require 'spec_helper'

describe 'Repository model' do

  it "supports creating a new repository" do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))

    repo = Repository.find(:repo_code => "TESTREPO")
    repo.name.should eq("My new test repository")
  end


  it "enforces ID uniqueness" do
    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                          :name => "My new test repository")) }.to_not raise_error

    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                          :name => "Another description")) }.to raise_error(Sequel::ValidationFailed)
  end


  it "enforces required fields" do

    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:name => "My new test repository")) }.to raise_error(JSONModel::ValidationException)

  end


  it "can transfer all records from one repository into another" do
    destination = make_test_repo("destination")
    source = make_test_repo("source")
    user_id = User[:username => RequestContext.get(:current_username)].id
    
    RequestContext.open(:repo_id => destination) do
      Preference.create_from_json(build(:json_preference),
                                  :user_id => user_id)
    end
    
    RequestContext.open(:repo_id => source) do
      Preference.create_from_json(build(:json_preference),
                                  :user_id => user_id)
    end

    records = []
    records << [Accession, create(:json_accession).id]
    records << [Resource, create(:json_resource).id]
    records << [DigitalObject, create(:json_digital_object).id]

    Repository[destination].assimilate(Repository[source])

    RequestContext.open(:repo_id => destination) do
      records.each do |model, id|
        model.this_repo[id].id.should eq(id)
      end
    end
  end


it "can identify and report conflicting identifiers" do
    destination = make_test_repo("destination")

    3.times do |i|
      create(:json_resource, :ead_id => "unique to this repository - #{i}")
    end

    source = make_test_repo("source")
    resource_ids = []
    3.times do |i|
      resource_ids << create(:json_resource, :ead_id => "unique to this repository - #{i}").id
    end

    expect {
      Repository[destination].assimilate(Repository[source])
    }.to raise_error {|e|
      e.should be_a(TransferConstraintError)
      e.conflicts.length.should eq(3)
      resource_ids.each do |resource_id|
        uri = "/repositories/#{source}/resources/#{resource_id}"
        e.conflicts[uri][0][:json_property].should eq(:ead_id)
      end
    }
  end
  

  it "can delete a repo even if it has preferences and import jobs and stuff" do

    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO2",
                                                                        :name => "electric boogaloo"))
    JSONModel.set_repository(repo.id)
    a_resource = create(:json_resource, { :extents => [build(:json_extent)] }) 
    accession = create(:json_accession,
                        :related_resources => [ {:ref => a_resource.uri } ])
    dobj = create(:json_digital_object ) 
    create(:json_digital_object_component, 
            :digital_object => { :ref => dobj.uri })
    
    resource = create(:json_resource, {                                                                                                                                                     
                        :extents => [build(:json_extent)],                                                                                                                                  
                        :related_accessions => [{ :ref => accession.uri }]                                                                                                                                                                  
    }) 
    create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1"  )
  
    classification = create(:json_classification,
             :title => "top-level classification",
             :identifier => "abcdef",
             :description => "A classification",
             :linked_records => [ 'ref' => resource.uri ])
    event = create(:json_event, :linked_records => [{'ref' => accession.uri, 'role' => generate(:record_role ) }] )


    group = Group.create_from_json(build(:json_group), :repo_id => repo.id)
    new_user = create(:user)
    new_user.add_to_groups(group)
   
    # ripping off from job spec
    converter = Class.new(Converter) do
      def self.instance_for(type, input_file)
          self.new(input_file) if type == 'nonce'
      end

      def run
        obj = ASpaceImport::JSONModel(:accession).new
        obj.title = IO.read(@input_file)
        obj.id_0 = '1234'
        obj.accession_date = '2010-10-10'
        @batch << obj
        @batch.flush
      end
    
    end
    # new we register it. 
    Converter.register_converter(converter)
   
    # let's add a temp file
    tmp = ASUtils.tempfile("doc-#{Time.now.to_i}")
    tmp.write("foobar")
    tmp.rewind
   
    # build out our job
    json = build(:json_job,
                :job_type => 'import_job',
                :job => build(:json_import_job, 
                              :filenames => [tmp.path], 
                              :import_type => 'nonce'))  
    jobber = create_nobody_user  
    job = Job.create_from_json(json, :repo_id => repo.id, :user => jobber)
    job.add_file(tmp) # add the temp file 

    # run the job. We should now have 
    job_runner = JobRunner.for(job)
    job_runner.run
  
    # we should have a JobCreatedRecord and a JobFile record
    job.created_records.count.should eq(1)
   
    # let's make a preference too
    RequestContext.open(:repo_id => repo.id) do
      Preference.create_from_json(build(:json_preference, :user_id => new_user.id))
    end
   
    #now let's delete this sucka
    RequestContext.open(:repo_id => repo.id) do
      repo.delete
      new_user.delete
    end
  
  end
end
