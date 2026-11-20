# frozen_string_literal: true

require_relative '../asutils'

describe ASUtils do
  describe '.file_url' do
    it 'builds a file:/// URL with spaces escaped' do
      expect(ASUtils.file_url('/tmp/dir with space/pdf_image')).to eq('file:///tmp/dir%20with%20space/pdf_image')
    end
  end
end
