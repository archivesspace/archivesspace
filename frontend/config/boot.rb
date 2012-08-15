require 'rubygems'
require 'stringio'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

# Hackery to suppress spurious git error messages from twitter-bootstrap-rails
old_stderr = $stderr
$stderr = StringIO.new
begin
  require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
ensure
  errors = $stderr.string.split(/\r?\n/).reject {|s| s =~ /Not a git repository/}
  $stderr = old_stderr

  if not errors.empty?
    errors.each do |line|
      $stderr.puts(line)
    end
  end
end

$:.unshift File.join(File.dirname(__FILE__), "..", "..", "common")
