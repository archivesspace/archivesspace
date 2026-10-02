require 'spec_helper'

describe RequestsController, type: :controller do

  describe 'the record a failed request returns to' do
    def submit(request_uri)
      post(:make_request, params: { request_uri: request_uri })
    end

    it 'is the requested record when the submitted URI is a record URI' do
      submit('/repositories/2/archival_objects/5')

      expect(response).to redirect_to('/repositories/2/archival_objects/5')
    end

    it 'is the site root when the submitted URI would leave the site' do
      submit('//evil.example/phish')

      expect(response).to redirect_to('/')
    end

    it 'is the site root when the submitted URI names an unrequestable type' do
      submit('/repositories/2/not_a_record_type/5')

      expect(response).to redirect_to('/')
    end

    it 'is the site root when the submitted URI is not a record URI at all' do
      submit('https://evil.example/phish')

      expect(response).to redirect_to('/')
    end

    it 'is the site root when no URI is submitted' do
      submit(nil)

      expect(response).to redirect_to('/')
    end
  end
end
