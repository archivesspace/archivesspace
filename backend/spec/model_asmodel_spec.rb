require 'spec_helper'

describe 'ASModel' do

  it "only allows repository or global scope" do
    repo = create(:repo)

    expect {
      repo.class.set_model_scope(:global)
      repo.class.set_model_scope(:repository)
    }.to_not raise_error

    expect {
      repo.class.set_model_scope(:banana)
    }.to raise_error
  end


  it "reports an error if scope isn't set" do
    repo = create(:repo)
    repo.class.instance_variable_set("@model_scope", nil)
    expect {
      repo.class.model_scope
    }.to raise_error(RuntimeError)
  end


  it "enforces suppression across repositories" do
    rep1 = make_test_repo("arepo")
    acc = create(:accession, :repo_id => rep1)
    acc.class.enable_suppression
    enf_sup_orig = RequestContext.get(:enforce_suppression)
    begin
      RequestContext.put(:enforce_suppression, true)
      acc.set_suppressed(true)
      acc.class.set_model_scope(:repository)

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
