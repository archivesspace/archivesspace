require 'spec_helper'

describe 'OAI config controller' do
  it "gets the OAI config record" do
    oai_config = create(:json_oai_config)

    oai_config_json = JSONModel(:oai_config).all.first
    expect(oai_config["oai_record_prefix"]).to eq(oai_config_json["oai_record_prefix"])
    expect(oai_config["oai_admin_email"]).to eq(oai_config_json["oai_admin_email"])
    expect(oai_config["oai_record_prefix"]).to eq(oai_config_json["oai_record_prefix"])
  end

  it "updates the OAI config record" do
    oai_config = create(:json_oai_config)

    oai_config.oai_admin_email = "foo@bar.com"
    oai_config.save

    oai_config_json = JSONModel(:oai_config).all.first
    expect(oai_config_json["oai_admin_email"]).to eq("foo@bar.com")
  end
end
