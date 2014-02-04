require 'spec_helper'

describe 'Record Suppression' do

  it "can suppress an accession record" do
    accession = create_accession
    accession.set_suppressed(true)

    create(:user, :username => 'nobody')

    as_test_user('nobody') do
      Accession.this_repo[accession.id].should eq(nil)
    end
  end

end