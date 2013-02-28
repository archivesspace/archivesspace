#!/usr/bin/env ruby
require 'optparse'
require 'nokogiri'


optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import.rb [options] IMPORTER_ARGS"
  

  opts.on( '-s', '--schema file PATH', 'Use the XSD at PATH' ) do|path|
    @schema = path
  end
  opts.on( '-d', '--document file PATH', 'Validate the XML document at PATH' ) do|path|
    @doc = path
  end
end

optparse.parse!

xsd = Nokogiri::XML::Schema(File.read(@schema))

doc = Nokogiri::XML(File.read(@doc))

errors = xsd.validate(doc)

puts "#{errors.length} errors:"

errors.each {|e| puts "#{e}\n\n"}




