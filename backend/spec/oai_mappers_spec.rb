require 'spec_helper'
require 'stringio'
require 'oai_helper'

describe 'OAI mappers output' do
  before(:all) do
    @oai_repo_id, @test_record_count, @test_resource_record, @test_archival_object_record = OAIHelper.load_oai_data
  end

  describe 'DC output' do 
    it "should map Conditions Governing Access and Conditions Governing Use to <dc:rights>" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace//repositories/#{@oai_repo_id}/resources/1&metadataPrefix=oai_dc"

      response = get uri
      expect(response.body).to match(/<dc:rights>conditions governing access note<\/dc:rights>/)
      expect(response.body).to match(/<dc:rights>conditions governing use note<\/dc:rights>/)

      expect(response.body).to_not match(/<dc:relation>conditions governing access note<\/dc:relation>/)
      expect(response.body).to_not match(/<dc:relation>conditions governing use note<\/dc:relation>/)
    end

    it "should map Extents to dc:format, not dc:extent" do
      uri = "/oai?verb=GetRecord&identifier=oai:archivesspace//repositories/#{@oai_repo_id}/resources/1&metadataPrefix=oai_dc"

      response = get uri

      expect(response.body).to match(/<dc:format>10 Volumes; Container summary<\/dc:format>/)
      expect(response.body).to match(/<dc:format>physical description note<\/dc:format>/)
      expect(response.body).to match(/<dc:format>dimensions note<\/dc:format>/)

      expect(response.body).to_not match(/<dc:extent>10 Volumes; Container summary<\/dc:extent>/)
      expect(response.body).to_not match(/<dc:extent>physical description note<\/dc:extent>/)
      expect(response.body).to_not match(/<dc:extent>dimensions note<\/dc:extent>/)
    end
  end
end