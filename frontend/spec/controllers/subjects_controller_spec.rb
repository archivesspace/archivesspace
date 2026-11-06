# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe SubjectsController, type: :controller do

  describe "terms_complete" do
    let(:term) { "TermsComplete#{SecureRandom.hex(4)}" }

    before(:each) do
      set_repo($repo)
      create(:json_subject, terms: [build(:json_term, term: term)])
    end

    def login_with_permissions(permissions)
      user = build(:json_user).save(password: "saa2020")
      user = User.find(user)
      create(:json_group,
             member_usernames: [user.username],
             grants_permissions: permissions)
      session = User.login(user.username, "saa2020")
      User.establish_session(controller, session, user.username)
      controller.send(:load_repository_list)
      controller.session[:repo] = $repo.uri
    end

    it "returns matching terms to users who can update subjects" do
      login_with_permissions(["view_repository", "manage_subject_record"])
      get :terms_complete, params: {query: term[0..-3]}
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).map {|t| t["term"]}).to include(term)
    end

    it "won't return terms to users who cannot update subjects" do
      login_with_permissions(["view_repository"])
      get :terms_complete, params: {query: term[0..-3]}
      expect(response.code).to eq "403"
    end
  end
end
