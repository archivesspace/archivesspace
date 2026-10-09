# frozen_string_literal: true

# jruby-rack 1.2.8 runs Bundler.setup itself, before loading config/boot.rb, when boot.rb looks like the
# Rails default (JRuby::Rack::RailsBooter::RailsEnvironment#rails_has_default_bundler_boot?). That would run
# before ASpaceGems.setup has pointed RubyGems at the bundled gems, and the deployed WARs would fail with
# GemNotFound (the devserver does not go through jruby-rack, so nothing else would catch it).
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
