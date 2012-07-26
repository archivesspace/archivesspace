#!/usr/bin/env ruby

require 'optparse'

options = {}
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: ead_import.rb [options] ead_file"
  options[:dry_run] = false
  opts.on( '-n', '--dry_run', 'Do a dry run' ) do
    options[:dry_run] = true
  end
  opts.on( '-i', '--importer NAME', 'Choose an importer' ) do|name|
    options[:importer] = name
  end
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

input_file = ARGV[0]
importer_file = File.join("importers", options[:importer])
require_relative(importer_file)

if File.exists? input_file
  i = Importer.new # is it a bad idea to have a library of files that all define the 'Importer' class?
  i.read(input_file)
end
