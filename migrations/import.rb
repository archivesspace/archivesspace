#!/usr/bin/env ruby
require 'optparse'
require_relative "config/config"

options = {:dry => false, 
           :debug => false,
           :relaxed => false, 
           :verbose => false, 
           :repo_id => ASpaceImportConfig::DEFAULT_REPO_ID, 
           :vocab_id => ASpaceImportConfig::DEFAULT_VOCAB_ID}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import.rb [options] IMPORTER_ARGS"
  
  opts.on( '-a', '--allow-failures', 'Do not stop because an import fails') do
    options[:relaxed] = true
  end
  opts.on( '-d', '--debug', 'Debug mode' ) do
    $DEBUG = true
    options[:debug] = true
  end 
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  opts.on( '-i', '--importer KEY', 'Select an importer' ) do|importer|
    options[:importer] = importer
  end
  opts.on( '-l', '--list-importers', 'List available importers') do
    options[:list] = true
  end
  opts.on( '-n', '--dry-run', 'Do a dry run' ) do
    options[:dry] = true
  end
  opts.on( '-r', '--repository REPO-ID', 'Override default repository id') do|repo_id|
    options[:repo_id] = repo_id
  end
  opts.on( '-w', '--vocabulary VOCAB-ID', 'Override default vocabulary id') do|vocab_id|
    options[:vocab_id] = repo_id
  end
  opts.on( '-s', '--source-file PATH', 'Import from file at PATH' ) do|path|
    options[:input_file] = path
  end
  opts.on( '-v', '--verbose', 'Exude verbosity') do
    options[:verbose] = true
  end
  opts.on( '-x', '--crosswalk KEY', 'Use crosswalk at crosswalks/KEY.yml' ) do|path|
    options[:crosswalk] = path
  end
end

optparse.parse!

$dry_mode = true if options[:dry]

if $dry_mode
  require 'mocha/setup'
  include Mocha::API
end

require File.join(File.dirname(__FILE__), "lib", "bootstrap")

if options[:list]
  ASpaceImport::Importer.list
  exit
end

if options[:importer]
  i = ASpaceImport::Importer.create_importer(options)
  i.run_safe
  puts i.report
end



