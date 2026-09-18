require 'spec_helper'

describe 'OAI config controller' do
  def current_oai_config
    JSONModel(:oai_config).all.first
  end

  it "gets the OAI config record" do
    oai_config = current_oai_config

    oai_config.oai_record_prefix = "archivesspace:oai"
    oai_config.oai_admin_email = "oairecord@example.org"
    oai_config.oai_repository_name = "ArchivesSpace OAI Repo"
    oai_config.save

    fetched = current_oai_config

    expect(fetched["oai_record_prefix"]).to eq("archivesspace:oai")
    expect(fetched["oai_admin_email"]).to eq("oairecord@example.org")
    expect(fetched["oai_repository_name"]).to eq("ArchivesSpace OAI Repo")
  end

  it "updates the OAI config record" do
    oai_config = current_oai_config

    oai_config.oai_admin_email = "foo@bar.com"
    oai_config.save

    expect(current_oai_config["oai_admin_email"]).to eq("foo@bar.com")
  end

  it "refuses an update from a stale copy of the record" do
    first = current_oai_config
    second = current_oai_config

    first.oai_admin_email = "first@example.com"
    first.save

    second.oai_admin_email = "second@example.com"

    expect { second.save }.to raise_error(ConflictException)
  end
end
