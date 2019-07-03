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


  it "can set a default language and script and retrieve them" do
    uri = "/repositories/#{JSONModel.repository}/default_values/resource"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(resource_defaults))
    defaults = JSONModel::HTTP.get_json(uri)

    defaults['defaults']['languages'] = {:language => "eng", :script => "Latn"}

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(defaults))

    expect(response.status).to eq(200)

    defaults = JSONModel::HTTP.get_json(uri)

    expect(defaults['defaults']['languages']['language']).to eq("eng")
    expect(defaults['defaults']['languages']['script']).to eq("Latn")
  end


  it "can set a default finding aid language and script and retrieve them" do
    uri = "/repositories/#{JSONModel.repository}/default_values/resource"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(resource_defaults))
    defaults = JSONModel::HTTP.get_json(uri)

    defaults['defaults']['finding_aid_language'] = "eng"
    defaults['defaults']['finding_aid_script'] = "Latn"

    response = JSONModel::HTTP.post_json(url, ASUtils.to_json(defaults))

    expect(response.status).to eq(200)

    defaults = JSONModel::HTTP.get_json(uri)

    expect(defaults['defaults']['finding_aid_language']).to eq("eng")
    expect(defaults['defaults']['finding_aid_script']).to eq("Latn")
  end


end
