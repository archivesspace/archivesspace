#!/usr/bin/env ruby

require 'nokogiri'

source_dir = ARGV[0]

output_file = ARGV[1] ||= 'frankenEAD.xml'


@doc = '<ead>'

@first = true

Dir.glob(File.dirname(__FILE__) + "/#{source_dir}/*.xml").each do |e|
  puts e
  reader = Nokogiri::XML::Reader(IO.read(e))
  
  reader.each do |node|

    if node.name == 'eadheader' and @first and node.node_type == 1
      @doc << node.outer_xml 
      @doc << '<archdesc level="collection">'
    end

    if node.name == 'arrangement' and @first and node.node_type == 1
      @doc << node.outer_xml
    end
    
    if node.name == 'dsc' and @first and node.node_type == 1
      @doc << '<dsc>'
    end

    if node.name == 'dsc' and node.node_type == 1
      @doc << node.inner_xml
    end

  end
  
  @first = false

end 

@doc << '</dsc></archdesc></ead>'

@doc.gsub!(/id="([a-zA-Z0-9]*)"/){|i| "id=\"#{rand(1000000)}\""}



File.open(output_file, 'w') { |f| f.write(@doc) }