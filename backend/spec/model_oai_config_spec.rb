require 'spec_helper'

describe 'OAIConfig model' do 

	it "knows how many rows are in table" do
		puts "++++++++++++++++++++++++++++++"
		puts OAIConfig.select.count
		puts OAIConfig.select.all.inspect

	end

	it "does not create an additional row in the OAIConfig table" do
		expect{OAIConfig.create(:oai_admin_email => "a@b.com",
												    :oai_repository_name => "foo",
												    :oai_record_prefix => "bar")}.to raise_error(Sequel::ValidationFailed)
	end

	it "requires oai_repository_name to be set" do
		oc = OAIConfig.first

		expect { oc.update(:oai_repository_name => "b", :oai_admin_email => "c@d", :oai_record_prefix => "sadf") }.to_not raise_error #(Sequel::ValidationFailed)
	end

end