# frozen_string_literal: true

# jruby-rack 1.2.8 runs Bundler.setup, before ASpaceGems.setup, when boot.rb looks like the Rails default
# (rails_has_default_bundler_boot?): the WARs fail with GemNotFound. The devserver skips jruby-rack.
describe 'Rails config/boot.rb under jruby-rack' do
  # the same check as jruby-rack 1.2.8 rails_has_default_bundler_boot?
  def jruby_rack_preboots_bundler?(content)
    %r{^\s*require\s+["']bundler/setup["']} =~ content &&
      %r{Bundler\.setup} !~ content &&
      %r{BUNDLE_WITHOUT} !~ content
  end

  %w[frontend public].each do |app|
    it "keeps #{app}/config/boot.rb out of jruby-rack's Bundler pre-boot" do
      boot_rb = File.expand_path("../../#{app}/config/boot.rb", __dir__)
      # only the code counts: a comment mentioning Bundler.setup must not be what keeps the pre-boot away
      code = File.readlines(boot_rb).grep_v(/^\s*#/).join

      expect(jruby_rack_preboots_bundler?(code)).to be_falsy
      expect(code).to match(/ASpaceGems\.setup.*Bundler\.setup/m)
    end
  end
end
