require 'spec_helper'

describe 'Touch Records mixin' do

  let(:resource) { create_resource({title: generate(:generic_title)}) }
  let(:digital_object) { create_digital_object({title: generate(:generic_title)}) }

  def gimme_ao(uri)
    create_archival_object({
      'resource' => {
        'ref' => uri
      }
    })
  end

  def gimme_doc(uri)
    create_digital_object_component({
      'digital_object' => {
        'ref' => uri
      }
    })
  end

  it 'can update resource system_mtime value when related ao created' do
    resource_mt = resource.system_mtime
    ArchivesSpaceService.wait(:long)
    obj = gimme_ao(resource.uri)

    resource.refresh

    expect(resource.system_mtime).not_to eq(resource_mt)
    expect(resource.system_mtime.to_i).to be >= obj.system_mtime.to_i
  end

  it 'can update resource system_mtime value when related ao updated' do
    ArchivesSpaceService.wait(:long)
    obj = gimme_ao(resource.uri)
    obj_mt = obj.system_mtime
    obj.system_mtime = Time.now + 120
    obj.save

    resource.refresh

    expect(obj.system_mtime).not_to eq(obj_mt)
    expect(resource.system_mtime.to_i).to be >= obj.system_mtime.to_i
  end

  it 'can update resource system_mtime value when related ao deleted' do
    obj = gimme_ao(resource.uri)
    resource.system_mtime = Time.now - 3600 # reset resource mtime after ao create
    resource.save

    obj_mt = obj.system_mtime
    obj.delete

    resource.refresh

    expect(resource.system_mtime.to_i).to be >= obj_mt.to_i
  end

  it 'works the same for digital objects and components' do
    ArchivesSpaceService.wait(:long)
    doc = gimme_doc(digital_object.uri)
    doc_mt = doc.system_mtime
    doc.system_mtime = Time.now + 120
    doc.save

    digital_object.refresh

    expect(doc.system_mtime).not_to eq(doc_mt)
    expect(digital_object.system_mtime.to_i).to be >= doc.system_mtime.to_i
  end

end
