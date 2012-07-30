#!/usr/bin/env ruby

require 'optparse'
require_relative File.join("lib", "bootstrap")

options = {}

=begin
Possible params to add:
  - flag for continuing if a single import fails
  - padd -h to the importer so it can declare what params it wants
=end

::ALLOWFAILURES = false
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
  opts.on( '-a', '--allow_failures', 'Do not stop because an import fails') do
    ::ALLOWFAILURES = true
  end
end

optparse.parse!


if options[:importer]
  i = ASpaceImporter.create_importer(options[:importer].to_sym)
  i.run
end


#input_file = ARGV[0]
#importer_file = File.join("importers", options[:importer])
#require_relative(importer_file)

#if File.exists? input_file
#  i = Importer.new # is it a bad idea to have a library of files that all define the 'Importer' class?
#  i.read(input_file)
#end
