require 'spec_helper'

describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    def empty_listing
      redirect_back(fallback_location: '/fallback')
    end

    def other_host_allowed
      redirect_back(fallback_location: '/fallback', allow_other_host: true)
    end

    def offsite_fallback
      redirect_back(fallback_location: '//evil.example/phish')
    end

    def landing
      render plain: 'landing'
    end
  end

  before(:each) do
    routes.draw do
      get 'anonymous/empty_listing' => 'anonymous#empty_listing'
      get 'anonymous/other_host_allowed' => 'anonymous#other_host_allowed'
      get 'anonymous/offsite_fallback' => 'anonymous#offsite_fallback'
      get 'anonymous/landing' => 'anonymous#landing'
    end
  end

  let(:listing_url) { 'http://test.host/anonymous/empty_listing' }

  describe 'a Referer that leads somewhere else' do
    it 'sends the visitor back to it' do
      request.env['HTTP_REFERER'] = 'http://test.host/repositories/1'

      get(:empty_listing)

      expect(response).to redirect_to('http://test.host/repositories/1')
    end
  end

  describe 'a Referer naming the URL being requested' do
    it 'uses the fallback rather than redirecting to itself' do
      request.env['HTTP_REFERER'] = listing_url

      get(:empty_listing)

      expect(response.location).not_to eq(listing_url)
      expect(response).to redirect_to('/fallback')
    end

    it 'uses the fallback when the Referer is sent as a relative path' do
      request.env['HTTP_REFERER'] = '/anonymous/empty_listing'

      get(:empty_listing)

      expect(response.location).not_to eq(listing_url)
      expect(response).to redirect_to('/fallback')
    end
  end

  describe 'a Referer on another host' do
    it 'uses the fallback rather than sending the visitor off-site' do
      request.env['HTTP_REFERER'] = 'https://evil.example/phish'

      get(:empty_listing)

      expect(response).to redirect_to('/fallback')
    end

    it 'follows it when the caller opts in' do
      request.env['HTTP_REFERER'] = 'https://elsewhere.example/page'

      get(:other_host_allowed)

      expect(response).to redirect_to('https://elsewhere.example/page')
    end
  end

  describe 'a fallback that would leave the site' do
    it 'redirects to the site root instead' do
      get(:offsite_fallback)

      expect(response).to redirect_to('/')
    end
  end

  describe 'a request with no usable Referer' do
    it 'uses the fallback when the header is absent' do
      get(:empty_listing)

      expect(response).to redirect_to('/fallback')
    end

    it 'uses the fallback when the header cannot be parsed' do
      request.env['HTTP_REFERER'] = 'http://[not a url'

      get(:empty_listing)

      expect(response).to redirect_to('/fallback')
    end
  end

  # A Referer that differs from the current URL can still lead to a page that
  # redirects straight back, which no single request can detect. Capping the
  # run at one bounce bounds any such cycle.
  describe 'a second redirect with no rendered page in between' do
    it 'uses the fallback even though the Referer leads elsewhere' do
      request.env['HTTP_REFERER'] = 'http://test.host/repositories/1'
      get(:empty_listing)
      expect(response).to redirect_to('http://test.host/repositories/1')

      request.env['HTTP_REFERER'] = 'http://test.host/repositories/1/resources'
      get(:empty_listing)

      expect(response).to redirect_to('/fallback')
    end

    it 'allows a bounce again once a response has rendered' do
      request.env['HTTP_REFERER'] = 'http://test.host/repositories/1'
      get(:empty_listing)
      expect(session).to have_key(ApplicationController::REDIRECTED_BACK_KEY)

      get(:landing)
      expect(session).not_to have_key(ApplicationController::REDIRECTED_BACK_KEY)

      request.env['HTTP_REFERER'] = 'http://test.host/repositories/2'
      get(:empty_listing)

      expect(response).to redirect_to('http://test.host/repositories/2')
    end
  end
end
