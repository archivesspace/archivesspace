require 'spec_helper'

describe 'Active Association mixin' do
  it 'can find the associated accession related to an extent record' do
    accession = Accession.create_from_json(
      build(:json_accession, :extents => [build(:json_extent)])
    )
    extent = Extent.where(accession_id: accession.id).first
    expect(extent.find_associated_type).to eq :accession
    expect(extent.active_association.class).to eq accession.class
    expect(extent.active_association.id).to eq accession.id
  end

  it 'can find the associated resource related to an extent record' do
    resource = Resource.create_from_json(
      build(:json_resource, :extents => [build(:json_extent)])
    )
    extent = Extent.where(resource_id: resource.id).first
    expect(extent.find_associated_type).to eq :resource
    expect(extent.active_association.class).to eq resource.class
    expect(extent.active_association.id).to eq resource.id
  end

  it 'can find the associated record and nudge it for reindexing' do
    digital_object = DigitalObject.create_from_json(
      build(:json_digital_object, :extents => [build(:json_extent)])
    )
    digital_object_original_mtime = digital_object.system_mtime
    ArchivesSpaceService.wait(2)
    extent = Extent.where(digital_object_id: digital_object.id).first
    extent.broadcast_reindex
    digital_object.refresh
    expect(digital_object.system_mtime).to be > digital_object_original_mtime
  end
end
