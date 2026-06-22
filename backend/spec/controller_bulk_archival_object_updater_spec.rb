require 'spec_helper'

describe 'Bulk Archival Object Updater controller' do
  let(:resource) { create(:json_resource) }
  let!(:archival_object) do
    create(:json_archival_object, resource: { ref: resource.uri })
  end
  let(:repo_id) { resource.repository['ref'].split('/').last }

  let(:base_params) do
    {
      'resource_uri' => resource.uri,
      'min_subrecords' => 0,
      'extra_subrecords' => 0,
      'min_notes' => 0
    }
  end

  describe 'Download bulk_archival_object_updater spreadsheet' do
    it 'accepts uri as a JSON-encoded array string and returns an XLSX spreadsheet' do
      response = JSONModel::HTTP.post_form(
        "/bulk_archival_object_updater/repositories/#{repo_id}/generate_spreadsheet",
        base_params.merge('uri' => ASUtils.to_json([archival_object.uri]))
      )

      expect(response.code).to eq('200')
      expect(response['Content-Type']).to include('spreadsheetml.sheet')
    end

    it 'accepts multiple uris in the JSON-encoded array' do
      ao2 = create(:json_archival_object, resource: { ref: resource.uri })

      response = JSONModel::HTTP.post_form(
        "/bulk_archival_object_updater/repositories/#{repo_id}/generate_spreadsheet",
        base_params.merge('uri' => ASUtils.to_json([archival_object.uri, ao2.uri]))
      )

      expect(response.code).to eq('200')
      expect(response['Content-Type']).to include('spreadsheetml.sheet')
    end

    it 'returns a 400 error when uri is not valid JSON' do
      archival_object

      response = JSONModel::HTTP.post_form(
        "/bulk_archival_object_updater/repositories/#{repo_id}/generate_spreadsheet",
        base_params.merge('uri' => 'not-valid-json')
      )

      expect(response.code).to eq('400')
    end
  end
end
