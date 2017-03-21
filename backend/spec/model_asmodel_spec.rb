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
    }.to_not raise_error

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
        Accession.any_repo[acc.id].should eq(nil)
      end
    ensure
      RequestContext.put(:enforce_suppression, enf_sup_orig)
    end
  end

end
