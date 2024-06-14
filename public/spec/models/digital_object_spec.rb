require "spec_helper"

describe DigitalObject, type: :model do

  let(:digital_object_uri) { "/repositories/1/digital_objects/1" }

  let(:linked_instances) {
    resource = build(:json_resource, publish: true, instances: [])
    resource.uri = "/repositories/0/resources/0"
    archival_object = build(:json_archival_object, publish: true, resource: { ref: resource.uri })
    archival_object.uri = "/repositories/0/archival_objects/1"
    accession_published = build(:json_accession, publish: true)
    accession_published.uri = "/repositories/0/accessions/1"
    accession_unpublished = build(:json_accession, publish: false)
    accession_unpublished.uri = "/repositories/0/accessions/2"
    # not a perfect image of the solr documents passed through the backend resolver,
    # but close enough:
    [ resource, archival_object, accession_published, accession_unpublished ].map { |json|
      json.to_hash.merge({ 'primary_type' => json.jsonmodel_type, 'json' => json.to_hash })
    }
  }

  let(:repository) {
    repo = build(:json_repository)
    repo.uri = "/repositories/0"
    repo
  }
  let(:solr_result) {
    {
      'primary_type' => 'digital_object',
      'json' => {
        'title' => 'TITLE',
        'repository' => {
          '_resolved' => repository.to_hash
        },
        'linked_instances' => linked_instances.map { |i| { 'ref' => i['uri'] } },
      },
      'uri' => digital_object_uri,
      '_resolved_linked_instance_uris' => Hash[linked_instances.map { |i| [i['uri'], [i]] }],
    }
  }

  it "builds linked_instances property from solr result document, filter out unpublished records" do
    digital_object = DigitalObject.new(solr_result)
    expect(digital_object.linked_instances.keys.size).to eq(3)
    expect(digital_object.linked_instances.values.map {|rec| rec.class }).to eq([Resource, ArchivalObject, Accession])
  end
end
