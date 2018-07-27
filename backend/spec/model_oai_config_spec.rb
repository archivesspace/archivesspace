require 'spec_helper'

describe 'OAIConfig model' do 

	it "knows how many rows are in table" do
		puts "++++++++++++++++++++++++++++++"
		puts OAIConfig.select.count

	end

	it "requires a value for oai_record_prefix" do
		expect ark = OAIConfig.create(:oai_admin_email => "a@b.com",
															    :oai_repository_name => "foo").to raise_error(Sequel::ValidationFailed)
	end

end