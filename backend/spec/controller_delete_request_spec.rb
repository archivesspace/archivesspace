require 'spec_helper'

describe 'Delete request controller' do

  def perform_delete(record_uris)
    uri = "/batch_delete"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    JSONModel::HTTP.post_json(url, {:record_uris => record_uris})
  end


  it "can delete multiple archival records" do
    record_1 = create(:json_resource)
    record_2 = create(:json_archival_object)
    record_3 = create(:json_accession)
    record_4 = create(:json_digital_object)
    record_5 = create(:json_digital_object_component)


    uri = "/batch_delete"
    url = URI("#{JSONModel::HTTP.backend_url}#{uri}")

    response = perform_delete([record_1.uri, record_2.uri, record_3.uri, record_4.uri, record_5.uri])
    response.code.should eq('200')

    expect {
      JSONModel(:resource).find(record_1.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:archival_object).find(record_2.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:accession).find(record_3.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:digital_object).find(record_4.id)
    }.to raise_error(RecordNotFound)

    expect {
      JSONModel(:digital_object_component).find(record_5.id)
    }.to raise_error(RecordNotFound)
  end


  it "throws an exception when one of the uris does not exist" do
    a_404_uri = "/idontexist"

    response = perform_delete([a_404_uri])

    response.code.should eq('403')

    response_json = ASUtils.json_parse(response.body)

    response_json["error"]["failures"][0]["uri"].should eq(a_404_uri)
  end

end
