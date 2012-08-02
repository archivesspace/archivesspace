#!/usr/bin/env ruby

require 'optparse'
require_relative File.join("lib", "bootstrap")
Dir.glob(File.dirname(__FILE__) + '/importers/*', &method(:require))

options = {:dry => false, :relaxed => false, :verbose => false, :repo => ASpaceImportConfig::DEFAULT_REPO_ID}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: ead_import.rb [options] ead_file"
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
  opts.on( '-r', '--repository REPO-CODE', 'Override default repository code / id') do|repo|
    options[:repo] = repo
    # TODO 
  end
end

optparse.parse!

if options[:list]
  ASpaceImporter.list
  exit
end


if options[:importer]
#  i = ASpaceImporter.create_importer(options[:importer].to_sym)
  i = ASpaceImporter.create_importer(options)
  i.run
  i.report
end


#input_file = ARGV[0]
#importer_file = File.join("importers", options[:importer])
#require_relative(importer_file)

#if File.exists? input_file
#  i = Importer.new # is it a bad idea to have a library of files that all define the 'Importer' class?
#  i.read(input_file)
#end
