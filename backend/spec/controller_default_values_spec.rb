require 'spec_helper'

describe 'Default Values' do

  let(:resource_defaults) {
    {
      "record_type" => "resource",
      "defaults" => {
        "title" => "TITLE"
      }
    }
  }


  it "can create a default value set for a record type and get it back" do
    uri = "/repositories/#{JSONModel.repository}/default_values/resource"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(resource_defaults))

    expect(response.status).to eq(200)

    defaults = JSONModel::HTTP.get_json(uri)

    expect(defaults['defaults']['title']).to eq('TITLE')
  end


  it "can overwrite a default value set for a record type" do
    uri = "/repositories/#{JSONModel.repository}/default_values/resource"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(resource_defaults))

    defaults = JSONModel::HTTP.get_json(uri)


    defaults['defaults']['title'] = "NEW TITLE"

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(defaults))

    expect(response.status).to eq(200)

    defaults = JSONModel::HTTP.get_json(uri)

    expect(defaults['defaults']['title']).to eq('NEW TITLE')

  end



end
