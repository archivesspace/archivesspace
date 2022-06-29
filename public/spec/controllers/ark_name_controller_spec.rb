require 'spec_helper'

ArkJsonMock = Struct.new(:json)

ArkQueryResponseMock = Struct.new(:record_uri, :external_ark) do
  def records
    if self.record_uri == :not_found
      []
    else
      [
        ArkJsonMock.new({
                          'uri' => self.record_uri,
                          'external_ark_url' => self.external_ark,
                        })
      ]
    end
  end

  def first
    records.first
  end
end


describe('with external ARKs enabled') do
  before(:all) do
    AppConfig[:arks_allow_external_arks] = true
  end

  describe ArkNameController, type: :controller do
    it "should redirect to the correct URL for a resource" do
      ArchivesSpaceClient.instance.stub(:advanced_search) {
        ArkQueryResponseMock.new('/repositories/5/resources/4')
      }

      response = get :show, params: {:ark_id => "f00001/1"}

      expect(response.location).to match(/\/repositories\/5\/resources\/4/)
    end

    it "should redirect to the correct URL for an archival object" do
      ArchivesSpaceClient.instance.stub(:advanced_search) {
        ArkQueryResponseMock.new('/repositories/5/archival_objects/4')
      }

      response = get :show, params: {:ark_id => "f00001/1"}

      expect(response.location).to match(/\/repositories\/5\/archival_objects\/4/)
    end

    it "should redirect external ark URL" do
      ArchivesSpaceClient.instance.stub(:advanced_search) {
        ArkQueryResponseMock.new('/repositories/5/archival_objects/4', 'http://example.com')
      }

      response = get :show, params: {:ark_id => "f00001/1"}

      expect(response.location).to eq("http://example.com")
    end

    it "should render to not found when not found" do
      ArchivesSpaceClient.instance.stub(:advanced_search) {
        ArkQueryResponseMock.new(:not_found)
      }

      response = get :show, params: {:ark_id => "f00001/1"}

      expect(response).to render_template('shared/not_found')
    end
  end
end
