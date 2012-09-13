require_relative "../lib/bootstrap"

if ENV['COVERAGE_REPORTS']
  require 'tmpdir'
  require 'pp'
  require 'simplecov'

  SimpleCov.root(File.join(File.dirname(__FILE__), "../../"))
  SimpleCov.coverage_dir("migrations/coverage")

  SimpleCov.start do
    # Exclude everything but the Import code

  end
  
  env_coverage_reports_tmp = ENV['COVERAGE_REPORTS'].clone
  
  ENV['COVERAGE_REPORTS'] = nil
  
end


require_relative '../../backend/spec/spec_helper'

def make_test_vocab
  vocab = JSONModel(:vocabulary).from_hash("ref_id" => 'test_vocab',
                                          "name" => "Test Vocabulary")
  vocab.save
  
  vocab.uri
end

if env_coverage_reports_tmp
  ENV['COVERAGE_REPORTS'] = env_coverage_reports_tmp
end







