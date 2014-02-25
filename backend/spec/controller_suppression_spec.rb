require 'spec_helper'

describe 'Record Suppression' do

  it "prevents updates to suppressed accession records" do
    test_accession = create_accession
    test_accession.set_suppressed(true)

    test_accession = JSONModel(:accession).find(test_accession.id)
    test_accession.title = "A new update"

    expect {
      test_accession.save
    }.to raise_error(ReadOnlyException)
  end


  it "prevents a regular update user from changing a record's suppression" do
    test_accession = create(:json_accession)

    create_nobody_user
    archivists = JSONModel(:group).all(:group_code => "repository-archivists").first
    archivists.member_usernames = ['nobody']
    archivists.save

    expect {
      as_test_user('nobody') do
        test_accession.suppress
      end
    }.to raise_error(AccessDeniedException)

    test_accession.suppress

    expect {
      as_test_user('nobody') do
        test_accession.unsuppress
      end
    }.to raise_error(AccessDeniedException)

    test_accession.unsuppress

    # Sneaky side attack by setting the attribute directly
    as_test_user('nobody') do
      test_accession = JSONModel(:accession).find(test_accession.id)
      test_accession["suppressed"] = true
      test_accession.save

      # Attempted change to suppress status got ignored
      JSONModel(:accession).find(test_accession.id).should_not eq(nil)
    end
  end

end
