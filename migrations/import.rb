#!/usr/bin/env ruby

require 'optparse'
require File.join(File.dirname(__FILE__), "lib", "bootstrap")
Dir.glob(File.dirname(__FILE__) + '/importers/*', &method(:require))

options = {:dry => false, :relaxed => false, :verbose => false, :repo_key => ASpaceImportConfig::DEFAULT_REPO_KEY}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import.rb [options] IMPORTER_ARGS"
  opts.on( '-n', '--dry-run', 'Do a dry run' ) do
    options[:dry] = true
  end
  opts.on( '-i', '--importer NAME', 'Use importer NAME' ) do|name|
    options[:importer] = name
  end
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
  opts.on( '-a', '--allow-failures', 'Do not stop because an import fails') do
    options[:relaxed] = true
  end
  opts.on( '-l', '--list-importers', 'List available importers') do
    options[:list] = true
  end
  opts.on( '-v', '--verbose', 'Exude verbosity') do
    options[:verbose] = true
  end
  opts.on( '-r', '--repository REPO-CODE', 'Override default repository code / id') do|repo_key|
    options[:repo_key] = repo_key
  end
  opts.on( '-d', '--debug', 'Run in debug mode') do
    $DEBUG = true
  end

end

optparse.parse!

if options[:list]
  ASpaceImporter.list
  exit
end


if options[:importer]

  i = ASpaceImporter.create_importer(options)
  i.run
  i.report
end



