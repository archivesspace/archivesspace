# frozen_string_literal: true

require 'webmock'
require 'webmock/rspec/matchers'
require_relative '../ashttp'
require_relative '../config/config-distribution'

describe ASHTTP do
  describe '.user_agent' do
    before do
      allow(ASConstants).to receive(:VERSION).and_return('4.2.0')
      allow(AppConfig).to receive(:[]).with(:public_proxy_url).and_return('https://archives.edu/')
    end

    it 'names the product and the contact URL' do
      expect(ASHTTP.user_agent('https://library.example.edu/archives'))
        .to eq('ArchivesSpace/4.2.0 (+https://library.example.edu/archives)')
    end

    ['http://localhost:8081', 'http://127.0.0.1:8081', 'http://www.example.com', 'not a url', '', nil,
     'ftp://library.edu/'].each do |unusable|
      it "falls back to the public URL for #{unusable.inspect}" do
        expect(ASHTTP.user_agent(unusable)).to eq('ArchivesSpace/4.2.0 (+https://archives.edu/)')
      end
    end

    it 'names only the product when the public URL is a placeholder too' do
      allow(AppConfig).to receive(:[]).with(:public_proxy_url).and_return('http://localhost:8081')
      expect(ASHTTP.user_agent).to eq('ArchivesSpace/4.2.0')
    end

    it 'replaces spaces in an unknown version rather than putting them in the header' do
      allow(ASConstants).to receive(:VERSION).and_return('NO VERSION')
      expect(ASHTTP.user_agent).to eq('ArchivesSpace/NO-VERSION (+https://archives.edu/)')
    end
  end

  describe '.download_image' do
    # Not 'webmock/rspec': that blocks real connections in every spec of the
    # run, and other common specs (e.g. JSONModel streaming) make real requests.
    include WebMock::API
    include WebMock::Matchers

    let(:url) { 'https://images.example.org/logo.png' }

    before do
      WebMock.enable!
      allow(AppConfig).to receive(:[]).with(:public_proxy_url).and_return('http://localhost:8081')
    end

    after do
      WebMock.reset!
      WebMock.disable!
      @file&.unlink
    end

    it 'saves the image and identifies itself' do
      request = stub_request(:get, url)
                .with(headers: { 'User-Agent' => %r{\AArchivesSpace/\S+ \(\+https://archives.edu/\)\z},
                                 'Accept' => 'image/*' })
                .to_return(body: 'PNGDATA')

      @file = ASHTTP.download_image(url, contact_url: 'https://archives.edu/')

      expect(File.binread(@file.path)).to eq('PNGDATA')
      expect(request).to have_been_requested
    end

    it 'follows redirects' do
      stub_request(:get, url).to_return(status: 302, headers: { 'Location' => '/b.jpg' })
      stub_request(:get, 'https://images.example.org/b.jpg').to_return(body: 'JPGDATA')

      @file = ASHTTP.download_image(url)

      expect(File.binread(@file.path)).to eq('JPGDATA')
    end

    it 'gives up on redirect loops' do
      stub_request(:get, url).to_return(status: 302, headers: { 'Location' => url })

      expect(ASHTTP.download_image(url)).to be_nil
      expect(a_request(:get, url)).to have_been_made.times(ASHTTP::MAX_REDIRECTS + 1)
    end

    it 'does not follow a redirect to a non-http URL' do
      stub_request(:get, url).to_return(status: 302, headers: { 'Location' => 'file:///etc/passwd' })

      expect(ASHTTP.download_image(url)).to be_nil
    end

    it 'returns nil for an HTTP error' do
      stub_request(:get, url).to_return(status: 403)

      expect(ASHTTP.download_image(url)).to be_nil
    end

    it 'returns nil when the request times out' do
      stub_request(:get, url).to_timeout

      expect(ASHTTP.download_image(url)).to be_nil
    end

    it 'returns nil when the host is unreachable' do
      stub_request(:get, url).to_raise(Errno::ECONNREFUSED)

      expect(ASHTTP.download_image(url)).to be_nil
    end

    # No stubs here, so a real request would make WebMock raise
    ['/local/path.png', 'ftp://example.org/logo.png', 'file:///tmp/logo.png', 'not a url', '', nil].each do |bad_url|
      it "returns nil without a request for #{bad_url.inspect}" do
        expect(ASHTTP.download_image(bad_url)).to be_nil
      end
    end
  end
end
