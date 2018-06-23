require 'spec_helper'

describe 'Slug controller' do
	it "finds repository by slug for 'repositories' controller" do
    repo = Repository.create_from_json(JSONModel(:repository)
    								 .from_hash(:repo_code => "SLUG",
                                :name => "Repo with a slug",
                                :slug => "sluggy"))


    get "/slug?slug=sluggy&controller=repositories&action=show"
    response = JSON.parse(last_response.body)

    expect(response["id"]).to eq(repo[:id])
    expect(response["table"]).to eq("repository")
	end
end

