require 'rspec'
require 'nokogiri'


def parse(xml_string)
  doc = Nokogiri::XML.parse(xml_string)
  doc.remove_namespaces!
  doc
end
