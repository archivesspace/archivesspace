require 'spec_helper'

describe 'Record transfers' do

  before(:each) do
      @target_repo = create(:unselected_repo, {:repo_code => "TARGET_REPO"})
  end


  describe 'Archival Record Transfers' do

    before(:each) do
      @acc_id = create(:json_accession,
                       :rights_statements => [build(:json_rights_statement)]).id
    end


    it "allows an accession to be transferred from one repository to another" do
      expect(JSONModel::HTTP::post_form("/repositories/#{$repo_id}/accessions/#{@acc_id}/transfer",
                                 {"target_repo" => @target_repo.uri}).code).to eq('200')
    end


    it "ensures that the requesting user has the right permissions in both repositories" do
      archivist = make_test_user("archivist")
      Group[:group_code => 'repository-archivists', :repo_id => $repo_id].add_user(archivist)

      as_test_user('archivist') do
        # No permission in @target_repo
        expect(JSONModel::HTTP::post_form("/repositories/#{$repo_id}/accessions/#{@acc_id}/transfer",
                                   {"target_repo" => @target_repo.uri}).code).to eq('403')
      end

      # Grant permission
      RequestContext.open(:repo_id => @target_repo.id) do
        Group[:group_code => 'repository-archivists', :repo_id => @target_repo.id].add_user(archivist)
      end

      as_test_user('archivist') do
        # Fine now!
        expect(JSONModel::HTTP::post_form("/repositories/#{$repo_id}/accessions/#{@acc_id}/transfer",
                                   {"target_repo" => @target_repo.uri}).code).to eq('200')
      end

    end

  end


  describe 'Full repository transfers' do

    it "accepts a transfer request for the admin user" do
      response = JSONModel::HTTP::post_form("/repositories/#{$repo_id}/transfer",
                                            {"target_repo" => @target_repo.uri})
      expect(response).to be_ok
    end


    it "checks for transfer permissions in both repositories" do
      archivist = make_test_user("archivist")

      as_test_user('archivist') do
        # No permission in either repo
        expect(JSONModel::HTTP::post_form("/repositories/#{$repo_id}/transfer",
                                   {"target_repo" => @target_repo.uri}).code).to eq('403')
      end

      # Grant transfer permission in the source repo but not the target one
      Group[:group_code => 'repository-archivists', :repo_id => $repo_id].tap do |group|
        group.add_user(archivist)
        group.grant('transfer_repository')
      end

      as_test_user('archivist') do
        # Still failing due to missing permission in the target repo
        expect(JSONModel::HTTP::post_form("/repositories/#{$repo_id}/transfer",
                                   {"target_repo" => @target_repo.uri}).code).to eq('403')
      end


      RequestContext.open(:repo_id => @target_repo.id) do
        Group[:group_code => 'repository-archivists', :repo_id => @target_repo.id].tap do |group|
          group.add_user(archivist)
          group.grant('transfer_repository')
        end
      end


      # It works!
      expect(JSONModel::HTTP::post_form("/repositories/#{$repo_id}/transfer",
                                 {"target_repo" => @target_repo.uri}).code).to eq('200')

    end


    it "reports conflicts between the records in two repositories being merged" do
      identifier = {:id_0 => "unique", :id_1 => "unique", :id_2 => "unique", :id_3 => "unique"}

      source_acc = create(:json_accession, identifier)

      JSONModel::with_repository(@target_repo.id) do
        create(:json_accession, identifier)
      end

      response = JSONModel::HTTP::post_form("/repositories/#{$repo_id}/transfer",
                                            {"target_repo" => @target_repo.uri})

      expect(response.code).to eq('409')
      err = ASUtils.json_parse(response.body)

      expect(err['error'][source_acc.uri][0]['json_property']).to eq('id_0')
    end

  end

end
