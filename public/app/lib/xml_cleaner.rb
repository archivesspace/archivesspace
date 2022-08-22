# Document class used to process (potentially flawed) HTML on its way to becoming PDFs
# handles character entities and namespaces
class XMLCleaner < Nokogiri::XML::SAX::Document
  attr_accessor :file

  def initialize(file)
    @file = file
  end

  # gsub out all potentially problematic chars with entity references
  def entity_gsub!(chars)
    mapping = {
      '&' => '&amp;',
      '<' => '&lt;',
      '>' => '&gt;',
      '"' => '&quot;',
      "'" => '&apos;'
    }
    re = /&(?!amp;)|[<>'"]/
    chars.gsub!(re, mapping)
    chars
  end


  def start_element_namespace(name, attrs=[], prefix=nil, uri=nil, ns=[])
    return if name == 'ridiculous_wrapper_element'
    @file << "<#{name}"
    unless attrs.empty?
      attrs.each do |attr|
        @file << " #{attr.localname}=\"#{entity_gsub!(attr.value)}\""
      end
    end
    @file << '>'
  end

  def characters(chars)
    @file << entity_gsub!(chars)
  end

  def end_element_namespace(name, prefix= nil, uri=nil)
    return if name == 'ridiculous_wrapper_element'
    @file << '</' << name << '>'
  end

end
