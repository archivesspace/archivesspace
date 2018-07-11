require_relative "spec_helper"
require_relative '../app/lib/uri_resolver'

describe 'URIResolver' do

  let (:minimal_record) do
    {
      'uri' => '/repositories/2/resources/1',
      'title' => 'Record Title',
      'linked_record' => {'ref' => '/repositories/2/resources/2'},
      'another_linked_record' => {'ref' => '/repositories/2/resources/3'}}
  end

  let (:linked_minimal_record) do
    {'uri' => '/repositories/2/resources/2', 'title' => 'Record Title'}
  end

  let (:record_with_array_of_refs) do
    {
      'uri' => '/repositories/2/resources/3',
      'title' => 'Record Title',
      'linked_record' => [
        {'ref' => '/repositories/2/resources/1'},
        {'ref' => '/repositories/2/resources/2'}
      ]
    }
  end

  let (:mock_resolver) {
    MockResolver.new(minimal_record,
                     linked_minimal_record,
                     record_with_array_of_refs)
  }

  def apply_mock_resolver
    # Patch in our resolver for testing purposes
    allow(URIResolver::URIResolverImplementation).to receive(:resolvers) {
      [mock_resolver]
    }
  end

  def resolve(records, properties, use_mock_resolver = true)
    apply_mock_resolver if use_mock_resolver

    URIResolver.resolve_references(records, properties)
  end

  it "handles an empty records and empty resolve list" do
    resolve([], []).should eq ([])
  end

  it "makes no change if given a record but no properties to resolve" do
    resolve(minimal_record, []).should eq(minimal_record)
  end

  it "resolves a single record" do
    resolved = resolve(minimal_record, ['linked_record'])

    resolved['linked_record']['_resolved'].should eq(linked_minimal_record)
  end

  it "resolves an array of records" do
    resolved = resolve([minimal_record, minimal_record],
                       ['linked_record'])

    resolved.each do |record|
      record['linked_record']['_resolved'].should eq(linked_minimal_record)
    end
  end

  it "resolves refs even when they're in an array" do
    resolved = resolve(record_with_array_of_refs,
                       ['linked_record'])

    resolved['linked_record']
      .map {|ref| ref['_resolved']}
      .sort_by {|rec| rec['uri']}
      .should eq([minimal_record, linked_minimal_record])
  end

  it "only resolves the properties requested" do
    resolved = resolve(minimal_record, ['linked_record'])

    resolved['another_linked_record'].has_key?('_resolved').should be(false)
  end

  it "resolves nested properties at each level provided" do
    # Resolve from 3 to 1 to 2
    resolved = resolve(record_with_array_of_refs, ["linked_record::linked_record"])

    resolved['linked_record'][0]['_resolved']['linked_record']['_resolved'].should eq(linked_minimal_record)
  end

  it "resolves tree URIs" do
    resource = create(:json_resource)

    resolved = resolve({'tree' => {'ref' => JSONModel(:resource_tree).uri_for(nil, :resource_id => resource.id)}},
                       ['tree'],
                      use_mock_resolver = false)
  end

  it "provides a helper for detecting inter-repository links and invalid URIs" do
    expect {
      URIResolver.ensure_reference_is_valid("/repositories/3/resources/1",
                                            active_repository_id = 2)
    }.to raise_error(ReferenceError)

    apply_mock_resolver

    expect {
      URIResolver.ensure_reference_is_valid("/repositories/2/resources/1")
    }.to_not raise_error

    expect {
      URIResolver.ensure_reference_is_valid("/repositories/2/resources/999")
    }.to raise_error(ReferenceError)
  end

  it "converts a JSONModel record to a regular hash if one is provided" do
    resource = build(:json_resource)

    resolved = resolve(resource, ["invalid_property"])

    resolved.should eq(resource.to_hash(:trusted))
  end

  it "converts an array of JSONModel records to regular hashes if provided" do
    resource1 = build(:json_resource)
    resource2 = build(:json_resource)

    resolved = resolve([resource1, resource2], ["invalid_property"])

    resolved.should eq([resource1.to_hash(:trusted), resource2.to_hash(:trusted)])
  end

  class MockResolver < URIResolver::ResolverType
    def initialize(*records)
      @records = records
    end

    def handler_for(record_type)
      self
    end

    def resolve(uris)
      Hash[uris.map {|uri| [uri, record_for(uri)]}]
    end

    def record_exists?(uri)
      record_for(uri) rescue false
    end

    private

    def record_for(uri)
      result = @records.find {|record| record['uri'] == uri} or
        raise "Record not found: #{uri}"
    end
  end

end
