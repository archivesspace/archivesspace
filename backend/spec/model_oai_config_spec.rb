require 'spec_helper'

describe 'OAIConfig model' do 

	it "does not create an additional row in the OAIConfig table" do
		expect{OAIConfig.create(:oai_admin_email => "a@b.com",
												    :oai_repository_name => "foo",
												    :oai_record_prefix => "bar")}.to raise_error(Sequel::ValidationFailed)
	end

	it "requires oai_repository_name to be set" do
		oc = OAIConfig.first

		expect { oc.update(:oai_repository_name => nil, 
								       :oai_admin_email => "c@d", 
								       :oai_record_prefix => "sadf") }.to raise_error(Sequel::ValidationFailed)
	end

	it "requires oai_admin_email to be set" do
		oc = OAIConfig.first

		expect { oc.update(:oai_repository_name => "foo", 
								       :oai_admin_email => nil, 
								       :oai_record_prefix => "sadf") }.to raise_error(Sequel::ValidationFailed)
	end

	it "requires oai_record_prefix to be set" do
		oc = OAIConfig.first

		expect { oc.update(:oai_repository_name => "foo", 
								       :oai_admin_email => "a@b.com", 
								       :oai_record_prefix => nil) }.to raise_error(Sequel::ValidationFailed)
	end

	it "requires oai_admin_email to be an email address" do
		oc = OAIConfig.first

		expect { oc.update(:oai_repository_name => "foo", 
								       :oai_admin_email => "bargmail.com", 
								       :oai_record_prefix => "bim") }.to raise_error(Sequel::ValidationFailed)
	end
end