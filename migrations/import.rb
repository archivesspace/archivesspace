#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "lib", "bootstrap")
Dir.glob(File.dirname(__FILE__) + '/importers/*', &method(:require))

options = {:dry => false, :relaxed => false, :verbose => false, :repo_id => ASpaceImportConfig::DEFAULT_REPO_KEY}

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
  opts.on( '-r', '--repository REPO-ID', 'Override default repository id') do|repo_id|
    options[:repo_id] = repo_id
  end
  opts.on( '-s', '--source-file PATH', 'Import from file at PATH' ) do|path|
    options[:input_file] = path
  end
  opts.on( '-v', '--verbose', 'Exude verbosity') do
    options[:verbose] = true
  end
  opts.on( '-x', '--crosswalk PATH', 'Use crosswalk at PATH' ) do|path|
    options[:crosswalk] = path
  end
end

optparse.parse!

if options[:list]
  ASpaceImport::Importer.list
  exit
end

if options[:importer]
  puts "IMPORTER OPTS #{options.inspect}"
  i = ASpaceImport::Importer.create_importer(options)
  i.run
  i.report
end



