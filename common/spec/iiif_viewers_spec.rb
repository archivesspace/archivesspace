# frozen_string_literal: true

require_relative '../../scripts/tasks/iiif_viewers'

RSpec.describe IIIFViewers do
  let(:viewer) { IIIFViewers::UNIVERSAL_VIEWER }
  let(:chunk) { 'dist/umd/560.3d50ebd90220503763a4.js' }

  describe '.apply_patches!' do
    it 'guards OpenSeadragon against an empty IIIF sizes array' do
      files = {
        chunk => 'o.maxLevel=1;if(this.sizes){let e=this.sizes.length;const t=this.sizes.slice()',
        'dist/uv.html' => 'if(this.sizes){let e=this.sizes.length'
      }

      expect { described_class.apply_patches!(viewer, files) }.to output(/patched #{chunk}/).to_stdout

      expect(files[chunk]).to eq('o.maxLevel=1;if(this.sizes&&this.sizes.length>0){let e=this.sizes.length;const t=this.sizes.slice()')
      expect(files['dist/uv.html']).to eq('if(this.sizes){let e=this.sizes.length')
    end

    it 'leaves a release that already has the fix alone' do
      fixed = 'if(this.sizes&&0<this.sizes.length){let e=this.sizes.length'
      files = { chunk => fixed }

      expect { described_class.apply_patches!(viewer, files) }.to output(/already fixes .* remove this patch/).to_stdout

      expect(files[chunk]).to eq(fixed)
    end

    it 'refuses a release it can neither patch nor recognise as fixed' do
      files = { chunk => 'if(this.levelSizes){let e=this.levelSizes.length' }

      expect { described_class.apply_patches!(viewer, files) }.to raise_error(/cannot be bundled as is/)
    end
  end

  IIIFViewers::UNIVERSAL_VIEWER[:destination_directories].each do |dir|
    it "bundles a patched Universal Viewer in #{dir}" do
      sources = Dir[File.expand_path("../../#{dir}/umd/*.js", __dir__)].map { |path| File.binread(path) }

      expect(sources).not_to be_empty
      viewer[:patches].each do |patch|
        expect(sources.grep(patch[:pattern])).to be_empty
        expect(sources.grep(patch[:fixed])).not_to be_empty
      end
    end
  end
end
