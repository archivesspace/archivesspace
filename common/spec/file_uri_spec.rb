# frozen_string_literal: true

require_relative '../file_uri'

describe FileURI do
  describe '.allowed_scheme?' do
    ['http://example.com/a.jpg', 'https://example.com/a.pdf', 'HTTPS://example.com/a.pdf',
     '  https://example.com/a.pdf  ', 'data:image/png;base64,iVBORw0KGgo='].each do |uri|
      it "is true for #{uri.inspect}" do
        expect(FileURI.allowed_scheme?(uri)).to be true
      end
    end

    ['javascript:alert(1)', ' JavaScript:alert(1)', "java\tscript:alert(1)", "\u0001javascript:alert(1)",
     'vbscript:msgbox(1)', 'file:///etc/passwd', 'relative/path.pdf', '//example.com/a.pdf', '', nil].each do |uri|
      it "is false for #{uri.inspect}" do
        expect(FileURI.allowed_scheme?(uri)).to be false
      end
    end
  end
end
