#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "lib", "bootstrap")
Dir.glob(File.dirname(__FILE__) + '/importers/*', &method(:require))

options = {:dry => false, :relaxed => false, :verbose => false, :repo_key => ASpaceImportConfig::DEFAULT_REPO_KEY}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import.rb [options] IMPORTER_ARGS"
  opts.on( '-a', '--allow-failures', 'Do not stop because an import fails') do
    options[:relaxed] = true
  end
  opts.on( '-d', '--debug', 'Run in debug mode') do
    $DEBUG = true
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
  opts.on( '-r', '--repository REPO-CODE', 'Override default repository code / id') do|repo_key|
    options[:repo_key] = repo_key
  end
  opts.on( '-s', '--source-file NAME', 'Import from file NAME' ) do|name|
    options[:input_file] = name
  end
  opts.on( '-v', '--verbose', 'Exude verbosity') do
    options[:verbose] = true
  end
  opts.on( '-x', '--crosswalk NAME', 'Use crosswalk NAME' ) do|name|
    options[:crosswalk] = name
  end
end

optparse.parse!

if options[:list]
  ASpaceImport::Importer.list
  exit
end

if options[:importer]
  i = ASpaceImport::Importer.create_importer(options)
  i.run
  i.report
end



