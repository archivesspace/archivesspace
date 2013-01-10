require 'spec_helper'

describe 'Search controller' do

  it "has a search user that can view suppressed records" do
    accession = create(:json_accession)
    accession.suppress

    create_nobody_user

    as_test_user("nobody") do
      expect {
        JSONModel(:accession).find(accession.id)
      }.to raise_error(RecordNotFound)
    end

    as_test_user(User.SEARCH_USERNAME) do
      JSONModel(:accession).find(accession.id).should_not eq(nil)
    end
  end


  it "doesn't let the search user update records" do
    accession = create(:json_accession)

    as_test_user(User.SEARCH_USERNAME) do
      expect {
        accession.save
      }.to raise_error(AccessDeniedException)
    end

  end

end
