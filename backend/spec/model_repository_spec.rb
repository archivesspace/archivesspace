require 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Repository model' do

  it "supports creating a new repository" do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                        :name => "My new test repository"))

    repo = Repository.find(:repo_code => "TESTREPO")
    expect(repo.name).to eq("My new test repository")
  end

  it "creates permissions groups for repository" do
    repo = Repository.create_from_json(JSONModel(:repository).from_hash(:repo_code => "TESTREPO",
                                                                       :name => "My new test repository"))
    repo_groups = Group.where(:repo_id => repo.id).all

    adv_data_entry_found = 0
    basic_data_entry_found = 0
    manager_found = 0
    project_manager_found = 0
    archivist_found = 0
    viewers_found = 0

    repo_groups.each do |g|
      manager_found          += 1 if g.group_code_norm == "repository-managers"
      archivist_found        += 1 if g.group_code_norm == "repository-archivists"
      project_manager_found  += 1 if g.group_code_norm == "repository-project-managers"
      adv_data_entry_found   += 1 if g.group_code_norm == "repository-advanced-data-entry"
      basic_data_entry_found += 1 if g.group_code_norm == "repository-basic-data-entry"
      viewers_found          += 1 if g.group_code_norm == "repository-viewers"
    end

    expect(manager_found).to eq(1)
    expect(archivist_found).to eq(1)
    expect(project_manager_found).to eq(1)
    expect(adv_data_entry_found).to eq(1)
    expect(basic_data_entry_found).to eq(1)
    expect(viewers_found).to eq(1)
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
    create(:json_archival_object, :resource => {:ref => resource.uri}, :title => "AO1" )

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

  describe "slug tests with human_readable_urls enabled" do
    before(:all) do
      AppConfig[:use_human_readable_urls] = true
    end
    describe "slug autogen enabled" do
      describe "by name" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = false
        end
        it "autogenerates a slug via repo_code" do
          repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => true))
          expected_slug = clean_slug(repository[:repo_code])
          expect(repository[:slug]).to eq(expected_slug)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
        end
        it "autogenerates a slug via repo_code" do
          repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => true))
          expected_slug = clean_slug(repository[:repo_code])
          expect(repository[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => true, :repo_code => "Foo Bar Baz&&&&"))
          expect(repository[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          repository1 = Repository.create_from_json(build(:json_repository, :is_slug_auto => true, :repo_code => "foo"))
          repository2 = Repository.create_from_json(build(:json_repository, :is_slug_auto => true, :repo_code => "foo#"))
          expect(repository1[:slug]).to eq("foo")
          expect(repository2[:slug]).to eq("foo_1")
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => "foo"))
        repository.update(:name => rand(100000000))
        expect(repository[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => "foo"))
        repository.update(:repo_code => rand(100000000))
        expect(repository[:slug]).to eq("foo")
      end

      it "automatically sets the slug equal to the repo code if autogen is off and slug is empty" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => nil, :repo_code => "Foo Bar Baz"))
        expected_slug = clean_slug(repository[:repo_code])
        expect(repository[:slug]).to eq(expected_slug)
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false))
        repository.update(:slug => "Foo Bar Baz ###")
        expect(repository[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        repository1 = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => "foo"))
        repository2 = Repository.create_from_json(build(:json_repository, :is_slug_auto => false))

        repository2.update(:slug => "foo")

        expect(repository1[:slug]).to eq("foo")
        expect(repository2[:slug]).to eq("foo_1")
      end
    end
  end

  describe "slug tests with human_readable_urls disabled" do
    before(:all) do
      AppConfig[:use_human_readable_urls] = false
    end
    describe "slug autogen enabled" do
      describe "by name" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = false
        end
        it "autogenerates a slug via repo_code" do
          repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => true))
          expected_slug = clean_slug(repository[:repo_code])
          expect(repository[:slug]).to eq(expected_slug)
        end
      end
      describe "by id" do
        before(:all) do
          AppConfig[:auto_generate_slugs_with_id] = true
        end
        it "autogenerates a slug via repo_code" do
          repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => true))
          expected_slug = clean_slug(repository[:repo_code])
          expect(repository[:slug]).to eq(expected_slug)
        end
        it "cleans slug" do
          repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => true, :repo_code => "Foo Bar Baz&&&&"))
          expect(repository[:slug]).to eq("foo_bar_baz")
        end

        it "dedupes slug" do
          repository1 = Repository.create_from_json(build(:json_repository, :is_slug_auto => true, :repo_code => "foo"))
          repository2 = Repository.create_from_json(build(:json_repository, :is_slug_auto => true, :repo_code => "foo#"))
          expect(repository1[:slug]).to eq("foo")
          expect(repository2[:slug]).to eq("foo_1")
        end
      end
    end

    describe "slug autogen disabled" do
      before(:all) do
        AppConfig[:auto_generate_slugs_with_id] = false
      end
      it "slug does not change when config set to autogen by title and title updated" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => "foo"))
        repository.update(:name => rand(100000000))
        expect(repository[:slug]).to eq("foo")
      end

      it "slug does not change when config set to autogen by id and id updated" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => "foo"))
        repository.update(:repo_code => rand(100000000))
        expect(repository[:slug]).to eq("foo")
      end

      it "automatically sets the slug equal to the repo code if autogen is off and slug is empty" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => nil, :repo_code => "Foo Bar Baz"))
        expected_slug = clean_slug(repository[:repo_code])
        expect(repository[:slug]).to eq(expected_slug)
      end
    end

    describe "manual slugs" do
      it "cleans manual slugs" do
        repository = Repository.create_from_json(build(:json_repository, :is_slug_auto => false))
        repository.update(:slug => "Foo Bar Baz ###")
        expect(repository[:slug]).to eq("foo_bar_baz")
      end

      it "dedupes manual slugs" do
        repository1 = Repository.create_from_json(build(:json_repository, :is_slug_auto => false, :slug => "foo"))
        repository2 = Repository.create_from_json(build(:json_repository, :is_slug_auto => false))

        repository2.update(:slug => "foo")

        expect(repository1[:slug]).to eq("foo")
        expect(repository2[:slug]).to eq("foo_1")
      end
    end
  end

end
