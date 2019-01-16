require 'spec_helper'

describe 'Repository model' do

  it "supports creating a new repository" do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))

    repo = Repository.find(:repo_code => "TESTREPO")
    expect(repo.name).to eq("My new test repository")
  end


  it "can set OAI off or on" do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository",
                                                                        :oai_is_disabled => true))

    repo = Repository.find(:repo_code => "TESTREPO")
    expect(repo.oai_is_disabled).to eq(1)
  end

  it "can store settings for sets included in OAI export" do
    sets = [1, 2, 3]
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository",
                                                                        :oai_sets_available => sets.to_json))

    repo = Repository.find(:repo_code => "TESTREPO")
    expect(JSON::parse(repo.oai_sets_available)).to eq([1, 2, 3])
  end


  it "enforces ID uniqueness" do
    expect { Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                          :name => "My new test repository")) }.not_to raise_error

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
        expect(model.this_repo[id].id).to eq(id)
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
      expect(e).to be_a(TransferConstraintError)
      expect(e.conflicts.length).to eq(3)
      resource_ids.each do |resource_id|
        uri = "/repositories/#{source}/resources/#{resource_id}"
        expect(e.conflicts[uri][0][:json_property]).to eq(:ead_id)
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
    expect(job.created_records.count).to eq(1)

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

  describe "slug tests" do
    # These slug tests should be in a more generic place. Here out of convienence for now.
    # TODO: Move slug tests to a generic "ArchiveSpace Slugged Model" test
    it "automatically strips invalid chars from slug field" do
      id = make_test_repo("slugtest")
      repo = Repository.where(:id => id).first.update(:slug => "A Wierd! Slug# To? Use@")

      expect(repo[:slug]).to eq("A_Wierd_Slug_To_Use")
    end

    it "automatically de-duplicates slug names" do
      id1 = make_test_repo("slugtest1")
      id2 = make_test_repo("slugtest2")
      id3 = make_test_repo("slugtest3")

      repo1 = Repository.where(:id => id1).first.update(:slug => "Original")
      repo2 = Repository.where(:id => id2).first.update(:slug => "Original")
      repo3 = Repository.where(:id => id3).first.update(:slug => "Original")

      expect(repo1[:slug]).to eq("Original")
      expect(repo2[:slug]).to eq("Original_1")
      expect(repo3[:slug]).to eq("Original_2")
    end

    it "adds a leading underscore to numerical slugs" do
      id = make_test_repo("digit_test")

      repo = Repository.where(:id => id).first.update(:slug => "12345")

      expect(repo[:slug]).to eq("_12345")
    end

    it "autogenerates a random slug if processing makes it empty" do
      id = make_test_repo("digit_test")

      repo = Repository.where(:id => id).first.update(:slug => "??????????")

      expect(repo[:slug]).to match(/^[A-Z]{8}$/)
    end

    it "truncates a slug name longer than 50 chars" do
      id = make_test_repo("slugtest")
      repo = Repository.where(:id => id).first.update(:slug => "LongSlugNameLongSlugNameLongSlugNameLongSlugNameLongSlugNameLongSlugNameLongSlugNameLongSlugName")

      expected_slug = "LongSlugNameLongSlugNameLongSlugNameLongSlugNameLo"

      expect(repo[:slug]).to eq(expected_slug)
    end

    it "autogenerates a slug via name when configured to generate by name" do
      AppConfig[:auto_generate_slugs_with_id] = false 
      
      id = make_test_repo("slugtest")

      repo = Repository.where(:id => id).first.update(:is_slug_auto => 1)
      expected_slug = repo[:name].gsub(" ", "_")
                                 .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

      expect(repo[:slug]).to eq(expected_slug)
    end

    it "replaces mulitple underscores in slugs with a single underscore" do
      AppConfig[:auto_generate_slugs_with_id] = false 
      
      id = make_test_repo("slugtest")

      repo = Repository.where(:id => id).first.update(:slug => "foo___bar")

      expect(repo[:slug]).to eq("foo_bar")
    end

    it "strips leading and trailing underscores in slugs" do
      AppConfig[:auto_generate_slugs_with_id] = false 
      
      id = make_test_repo("slugtest")

      repo = Repository.where(:id => id).first.update(:slug => "_foo_bar_")

      expect(repo[:slug]).to eq("foo_bar")
    end

    it "autogenerates a slug via repo_code when configured to generate by id" do
      AppConfig[:auto_generate_slugs_with_id] = true
      
      id = make_test_repo("slugtest")

      repo = Repository.where(:id => id).first.update(:is_slug_auto => 1)
      expected_slug = repo[:repo_code].gsub(" ", "_")
                                 .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

      expect(repo[:slug]).to eq(expected_slug)
    end


    describe "slug code does not run" do
      it "does not execute slug code when auto-gen on id and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
  
        repository = FactoryBot.create(:repo, {:repo_code => "test#{rand(1000)}", 
                                               :org_code => "test#{rand(1000)}", 
                                               :name => "test#{rand(1000)}",
                                               :is_slug_auto => 1})

        expect(repository).to_not receive(:auto_gen_slug!) do |&block| 
          expect(block).to be(repository.update(:name => "foobar"))
        end
      end

      it "does not execute slug code when auto-gen on title and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false
  
        repository = FactoryBot.create(:repo, {:repo_code => "test#{rand(1000)}", 
                                               :org_code => "test#{rand(1000)}", 
                                               :name => "test#{rand(1000)}",
                                               :is_slug_auto => 1})

  

        expect(repository).to_not receive(:auto_gen_slug!) do |&block| 
          expect(block).to be(repository.update(:repo_code => "FOO"))
        end
      end

      it "does not execute slug code when auto-gen off and title, identifier changed" do

        repository = FactoryBot.create(:repo, {:repo_code => "test#{rand(1000)}", 
                                               :org_code => "test#{rand(1000)}", 
                                               :name => "test#{rand(1000)}",
                                               :is_slug_auto => 0})
  
        expect(SlugHelpers).to_not receive(:clean_slug) do |&block| 
          expect(block).to be(repository.update(repository.update(:repo_code => "FOO")))
        end

        expect(SlugHelpers).to_not receive(:clean_slug) do |&block| 
          expect(block).to be(repository.update(repository.update(:name => "barfoo")))
        end
      end

    end

    describe "slug code runs" do
      it "executes slug code when autogen is turned on" do
        AppConfig[:auto_generate_slugs_with_id] = false

        id = make_test_repo("slugtest#{rand(10000)}")
        repository = Repository.where(:id => id).first
        repository.update(:is_slug_auto => 0)
  
        expect(repository).to receive(:auto_gen_slug!)
  
        repository.update(:is_slug_auto => 1)
      end

      it "executes slug code when autogen is off and slug is updated" do
        id = make_test_repo("slugtest#{rand(10000)}")
        repository = Repository.where(:id => id).first
        repository.update(:is_slug_auto => 0)
  
        expect(SlugHelpers).to receive(:clean_slug)
  
        repository.update(:slug => "snow white")
      end

    end
  end
end
