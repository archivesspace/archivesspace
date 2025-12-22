require 'spec_helper'

describe "Batch Import Controller" do

  class BigID
    @big_id_root = Time.now.to_i
    def self.next
      @big_id_root += 1
    end
  end

  def big_id
    BigID.next
  end

  it "can import a batch of JSON objects" do
    batch_array = []

    types = [:json_resource, :json_archival_object]

    10.times do |i|
      obj = build(types.sample)
      obj.uri = obj.class.uri_for(i, {:repo_id => $repo_id})
      batch_array << obj.to_hash(:raw)
    end

    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)

    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(10)
  end

  describe 'migration mode' do
    let(:batch_array) do
      Array.new(10) do |i|
        build(:json_archival_object).tap do |obj|
          obj.uri = obj.class.uri_for(i, {:repo_id => $repo_id}) end
      end
    end

    def make_batch_import_request(migration_param)
      uri = "/repositories/#{$repo_id}/batch_imports?migration=#{migration_param}"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
      JSONModel::HTTP.post_json(url, batch_array.to_json)
    end

    shared_examples "returning a parameter validation error" do |migration_value|
      it "responds with a BooleanParam validation error" do
        expect(StreamingImport).not_to receive(:new)
        response = make_batch_import_request(migration_value)

        expect(response.code).to eq('400')
        expect(ASUtils.json_parse(response.body)['error']['migration'][0]).to match(/RESTHelpers::BooleanParam/)
      end
    end

    shared_examples "successfully importing a batch" do |migration_value, expected_migration_flag|
      it "successfully imports the batch" do
        expect(StreamingImport).to receive(:new).with(anything, anything, anything, expected_migration_flag).and_call_original
        response = make_batch_import_request(migration_value)

        expect(response.code).to eq('200')
        results = ASUtils.json_parse(response.body)
        expect(results.last['saved'].length).to eq(10)
      end
    end

    context 'with a string migration parameter' do
      context "set to 'false'" do
        it_behaves_like "returning a parameter validation error", "'false'"
      end

      context "set to 'true'" do
        it_behaves_like "returning a parameter validation error", "'true'"
      end
    end

    context 'with a boolean migration parameter' do
      context "set to false" do
        it_behaves_like "successfully importing a batch", false, false
      end

      context "set to true" do
        it_behaves_like "successfully importing a batch", true, true
      end
    end

    it "can import a batch of JSON objects from a migrator and not slam the database with checks if position is provided" do
      expect_any_instance_of(ArchivalObject).not_to receive(:set_position_in_list)

      response = make_batch_import_request(true)

      expect(response.code).to eq('200')
      results = ASUtils.json_parse(response.body)
      expect(results.last['saved'].length).to eq(10)
    end
  end

  it "can import a batch of JSON objects with unknown enum values" do

    # Set the enum source to the backend version
    old_enum_source = JSONModel.init_args[:enum_source]
    JSONModel.init_args[:enum_source] = BackendEnumSource


    begin
      batch_array = []

      enum = JSONModel::JSONModel(:enumeration).all.find {|obj| obj.name == 'resource_resource_type' }

      expect(enum.values).not_to include('spaghetti')

      obj = build(:json_resource, :resource_type => 'spaghetti')
      obj.uri = obj.class.uri_for(big_id, {:repo_id => $repo_id})

      batch_array << obj.to_hash(:raw)

      uri = "/repositories/#{$repo_id}/batch_imports"
      url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

      response = JSONModel::HTTP.post_json(url, batch_array.to_json)

      expect(response.code).to eq('200')

      results = ASUtils.json_parse(response.body)
      expect(results.last['saved'].length).to eq(1)

      enum = JSONModel::JSONModel(:enumeration).all.find {|obj| obj.name == 'resource_resource_type' }

      expect(enum.values).to include('spaghetti')
    ensure
      # set things back as they were enum-source wise
      JSONModel.init_args[:enum_source] = old_enum_source
    end
  end


  it "can import a batch containing a record with a reference to already existing records" do

    subject = create(:json_subject)
    accession = create(:json_accession)

    resource = build(:json_resource,
      :subjects => [{'ref' => subject.uri}],
      :related_accessions => [{'ref' => accession.uri}])



    resource.uri = resource.class.uri_for(big_id, {:repo_id => $repo_id})

    batch_array = [resource.to_hash(:raw)]


    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(1)

    real_id = results.last['saved'][resource.uri][-1]

    resource_reloaded = JSONModel(:resource).find(real_id, "resolve[]" => ['subjects', 'related_accessions'])

    expect(resource_reloaded.subjects[0]['ref']).to eq(subject.uri)
    expect(resource_reloaded.related_accessions[0]['ref']).to eq(accession.uri)

  end

  it "can import a batch containing a record with an inline (non-schematized) external id object" do

    resource = build(:json_resource, :external_ids => [{:external_id => '1',
      :source => 'jdbc:mysql://tracerdb.cyo37z0ucix8.us-east-1.rds.amazonaws.com/at2::RESOURCE'}])

    resource.uri = resource.class.uri_for(big_id, {:repo_id => $repo_id})

    batch_array = [resource.to_hash(:raw)]

    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(1)
  end


  it "cannot import a batch containing records with inter-repository references" do

    accession = create(:json_accession)

    new_repo = create(:repo)

    resource = build(:json_resource,
      :related_accessions => [{'ref' => accession.uri}])

    resource.uri = resource.class.uri_for(big_id, {:repo_id => $repo_id})

    batch_array = [resource.to_hash(:raw)]

    uri = "/repositories/#{new_repo.id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    url.query = URI.encode_www_form({:use_transaction => true})

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)

    expect(results.last['errors'].length).to eq(1)
    expect(results.last['errors'][0]).to match(/Inter\-repository links/)

    # try again - ensure the resource wasn't saved the first time

    resource.related_accessions = nil

    batch_array = [resource.to_hash(:raw)]

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(1)
  end


  it "cannot import a batch containing records with non-existent references" do

    accession = create(:json_accession)

    resource = build(:json_resource,
      :related_accessions => [{'ref' => accession.uri << "9"}])

    resource.uri = resource.class.uri_for(big_id, {:repo_id => $repo_id})

    batch_array = [resource.to_hash(:raw)]

    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    url.query = URI.encode_www_form({:use_transaction => true})

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)

    expect(results.last['errors'].length).to eq(1)
    expect(results.last['errors'][0]).to match(/Reference does not exist/)

    # try again - ensure the resource wasn't saved the first time

    resource.related_accessions = nil

    batch_array = [resource.to_hash(:raw)]

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(1)
  end


  it "creates a well-ordered resource tree" do
    resource = build(:json_resource)
    resource.uri = resource.class.uri_for(big_id, {:repo_id => $repo_id})

    a1 = build(:json_archival_object,
      :dates => [])
    a2 = build(:json_archival_object,
      :dates => [])
    a3 = build(:json_archival_object,
      :dates => [])

    a1.position = 1
    a2.position = 2
    a3.position = 3

    batch_array = [resource.to_hash(:raw)]
    [a3, a1, a2].each do |ao|
      ao.uri = ao.class.uri_for(big_id, {:repo_id => $repo_id})
      ao.resource = {:ref => resource.uri}
      batch_array << ao.to_hash(:raw)
    end

    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    url.query = URI.encode_www_form({:use_transaction => true})

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(4)
    r_id = results.last['saved'][resource.uri][1]

    r = JSONModel.JSONModel(:resource).find(r_id, "resolve[]" => ['tree'])
    children = r['tree']['_resolved']['children']

    expect(children.map {|child| child['title']}).to eq [a1, a2, a3].map {|a| a.title}
  end


  it "manages repeated position numbers in batch" do
    resource = build(:json_resource)
    resource.uri = resource.class.uri_for(123, {:repo_id => $repo_id})
    archival_objects = []
    (0..10).each do  |i|
      a = build(:json_archival_object,
        :dates => [])
      a.title = "AO #{i}"
      a.uri = a.class.uri_for(i, {:repo_id => $repo_id})
      a.resource = {:ref => resource.uri}
      a.position = i
      archival_objects[i] = a
    end

    correct_order = archival_objects.map { |a| a['title'] }

    # simulate a double entry
    archival_objects[-3..-1].each do |a|
      a.position = a.position - 1
    end

    # add a gap
    archival_objects[2..-1].each do |a|
      a.position = a.position + 1
    end

    batch_array = [resource.to_hash(:raw)]
    archival_objects.shuffle.each do |ao|
      batch_array << ao.to_hash(:raw)
    end

    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
    url.query = URI.encode_www_form({:use_transaction => true})

    response = JSONModel::HTTP.post_json(url, batch_array.to_json)
    expect(response.code).to eq('200')

    results = ASUtils.json_parse(response.body)
    r_id = results.last['saved'][resource.uri][1]

    r = JSONModel.JSONModel(:resource).find(r_id, "resolve[]" => ['tree'])
    children = r['tree']['_resolved']['children']

    result_order = children.map {|child| child['title']}

    # everything up to the double entry should be the same:
    expect(result_order[0..6]).to eq(correct_order[0..6])

    # everything after the double entry should be the same:
    expect(result_order[-2..-1]).to eq(correct_order[-2..-1])

    # (the double-entry members occupy 7 and 8)
  end


  it "respects the publish default user preference" do
    obj = build(:json_resource)
    obj.uri = obj.class.uri_for(big_id, {:repo_id => $repo_id})
    obj.publish = nil

    uri = "/repositories/#{$repo_id}/batch_imports"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, [obj].to_json)
    expect(response.code).to eq('200')
    results = ASUtils.json_parse(response.body)
    expect(results.last['saved'].length).to eq(1)

    real_id = results.last['saved'][obj.uri][-1]

    obj_reloaded = JSONModel(:resource).find(real_id)

    expect(obj_reloaded.publish).to eq(Preference.defaults['publish'])
  end

end
