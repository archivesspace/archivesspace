require 'spec_helper'

describe 'ASModel' do

  before(:all) do
    DB.open(true) do |db|
      db.create_table(:asmodel_spec) do
        primary_key :id
      end
    end

    class TestModel < Sequel::Model(:asmodel_spec)
      include ASModel
    end
  end

  it "only allows repository or global scope" do
    expect {
      TestModel.set_model_scope(:global)
      TestModel.set_model_scope(:repository)
    }.not_to raise_error

    expect {
      TestModel.set_model_scope(:banana)
    }.to raise_error(RuntimeError)
  end


  it "reports an error if scope isn't set" do
    TestModel.instance_variable_set("@model_scope", nil)
    expect {
      TestModel.model_scope
    }.to raise_error(RuntimeError)
  end


  it "reindexes top_containers when publish all is triggered through resource instance" do
    top = create(:json_top_container)
    opts = {:instances => [build(:json_instance,
                                 :sub_container => build(:json_sub_container,
                                                         :top_container => {:ref => top.uri}))],
            :publish => false}
    resource = create_resource(opts)
    res =
    URIResolver.resolve_references(Resource.to_jsonmodel(resource[:id]), ['top_container'])['instances'][0]["sub_container"]['top_container']['_resolved']
    pretime = res['system_mtime']

    ArchivesSpaceService.wait(:long)
    resource.publish!

    res =
    URIResolver.resolve_references(Resource.to_jsonmodel(resource[:id]), ['top_container'])['instances'][0]["sub_container"]['top_container']['_resolved']
    posttime = res['system_mtime']

    expect(pretime).not_to match(posttime)
  end

  it "reindexes top_containers when publish all is triggered through archival object instance" do
    top = create(:json_top_container)
    (resource, _, _, child) = create_tree(top, { grandparent_properties: { publish: false } })
    res =
    URIResolver.resolve_references(child, ['top_container'])['instances'][0]["sub_container"]['top_container']['_resolved']
    pretime = res['system_mtime']

    ArchivesSpaceService.wait(:long)
    resource.publish!

    res =
    URIResolver.resolve_references(child, ['top_container'])['instances'][0]["sub_container"]['top_container']['_resolved']
    posttime = res['system_mtime']

    expect(pretime).not_to match(posttime)
  end

  it "enforces suppression across repositories" do
    rep1 = make_test_repo("arepo")
    acc = create(:accession, :repo_id => rep1)
    enf_sup_orig = RequestContext.get(:enforce_suppression)
    begin
      RequestContext.put(:enforce_suppression, true)
      acc.set_suppressed(true)

      rep2 = make_test_repo("anotherrepo")
      create(:user, :username => 'nobody')
      as_test_user('nobody') do
        expect(Accession.any_repo[acc.id]).to be_nil
      end
    ensure
      RequestContext.put(:enforce_suppression, enf_sup_orig)
    end
  end

end
