require 'rspec'
require 'nokogiri'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'gems', 'oclc-auth-0.1.1', 'lib')))

def get_wscred
  YAML.load_file("#{File.dirname(__FILE__)}/wskey.yml")
end


def parse(xml_string)
  doc = Nokogiri::XML.parse(xml_string)
  doc.remove_namespaces!
  doc
end

