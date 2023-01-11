RSpec::Matchers.define :have_node do |path|
  match do |actual|
    if actual.at(path)
      true
    else
      false
    end
  end
  failure_message do |actual|
    prefix = ""
    while path.slice(0) == '/'
      prefix << path.slice!(0)
    end
    root_frags = path.split('/').reject {|f| f.empty?}
    node_frags = []
    matched_node = nil
    while (matched_node.nil? && root_frags.length > 1)
      node_frags.unshift(root_frags.pop)
      node_set = actual.xpath(prefix + root_frags.join('/'))
      unless node_set.empty?
        matched_node = prefix + root_frags.join('/')
      end
    end

    if matched_node
      display_xml = node_set.map {|node| node.to_xml.gsub(/[\n]/, ' ').strip}.join("\n====END\n\n==BEGIN\n")
      "Expected to find node: #{node_frags.join('/')} within the following XML:\n==BEGIN\n#{display_xml}\n====END"
    elsif actual.respond_to?(:length) #node set
      xml = actual.length > 0 ? actual.to_xml : "<Empty node set>."
      "Expected to find #{path} within node set: #{xml}."
    else
      "Expected XML document to contain node #{path}."
    end
  end
  failure_message_when_negated do |actual|
    "Expected that #{actual} would not have node #{path}."
  end
  description do
    "have node: #{expected}"
  end
end


RSpec::Matchers.define :have_attribute do |att, val|
  match do |node|
    if node && val
      node.attr(att) && node.attr(att) == val
    elsif node
      node.attr(att)
    else
      false
    end
  end

  failure_message do |node|
    if node.nil?
      "Ooops - looks like we tried to check `nil` for an XML attribute! Check your XPath?"
    elsif val and node.attr(att)
      "Expected '#{node.name}/@#{att}' to be '#{val}', not '#{node.attr(att)}'."
    else
      "Expected the node '#{node.name}' to have the attribute '#{att}'."
    end
  end

  failure_message_when_negated do |node|
    "Unexpected attribute '#{att}' on node '#{node.name}'."
  end
end


RSpec::Matchers.define :have_inner_text do |expected|
  regex_mode = expected.is_a?(Regexp)

  match do |node|
    if regex_mode
      node.inner_text =~ expected
    else
      node.inner_text.strip == expected.strip
    end
  end

  failure_message do |node|
    infinitive = regex_mode ? "match /#{expected}/" : "contain '#{expected}'"
    name = node.is_a?(Nokogiri::XML::NodeSet) ? node.map {|n| n.name}.uniq.join(' | ') : node.name
    "Expected node '#{name}' to #{infinitive}. Found string: '#{node.inner_text}'."
  end

  failure_message_when_negated do |node|
    name = node.is_a?(Nokogiri::XML::NodeSet) ? node.map {|n| n.name}.uniq.join(' | ') : node.name
    "Expected node '#{name}' to contain something other than '#{txt}'."
  end
end

RSpec::Matchers.define :have_inner_markup do |expected|
  regex_mode = expected.is_a?(Regexp)

  match do |node|
    if regex_mode
      markup =~ expected
    else
      markup = node.inner_html.strip.delete(' ').gsub("'", '"')
      expected_markup = expected.strip.delete(' ').gsub("'", '"')
      markup == expected_markup
    end
  end

  failure_message do |node|
    markup = node.inner_html.strip.delete(' ').gsub("'", '"')
    expected_markup = expected.strip.delete(' ').gsub("'", '"')
    infinitive = regex_mode ? "match /#{expected}/" : "contain '#{expected_markup}'"
    name = node.is_a?(Nokogiri::XML::NodeSet) ? node.map {|n| n.name}.uniq.join(' | ') : node.name
    "Expected node '#{name}' to #{infinitive}. Found string: '#{markup}'."
  end

  failure_message_when_negated do |node|
    name = node.is_a?(Nokogiri::XML::NodeSet) ? node.map {|n| n.name}.uniq.join(' | ') : node.name
    "Expected node '#{name}' to contain something other than '#{txt}'."
  end
end

RSpec::Matchers.define :have_tag do |expected, attributes = {}|
  raise "spec argument error" if expected.is_a?(Hash) && attributes.has_key?(:_text)
  attributes[:_text] = expected.values[0] if expected.is_a?(Hash)
  attributes_orig = attributes.dup
  tag = expected.is_a?(Hash) ? expected.keys[0] : expected
  nodeset = nil

  match do |doc|
    nodeset = if doc.namespaces.empty?
                doc.xpath("//#{tag}")
              else
                tag_frags = tag.gsub(/^\//, '').split('/')
                path_root = tag_frags.shift
                tag = path_root =~ /^[^\[]+:.+/ ? path_root : "xmlns:#{path_root}"
                selector = false

                tag_frags.each do |frag|
                  join = (selector || frag =~ /^[^\[]+:.+/) ? '/' : '/xmlns:'
                  tag << "#{join}#{frag}"
                  if frag =~ /\[[^\]]*$/
                    selector = true
                  elsif frag =~ /\][^\[]*$/
                    selector = false
                  end
                end
                doc.xpath("//#{tag}", doc.namespaces)
              end

    if nodeset.empty?
      false
    else
      nodeset.any? {|node| check_node(node, attributes) }
    end
  end

  failure_message do |doc|
    if nodeset.nil? || nodeset.empty?
      outermost_missing_tag_message(doc, tag)
    else
      "Could not find text/attributes '#{attributes_orig.inspect}' in #{nodeset.to_xml}"
    end
  end

  failure_message_when_negated do |doc|
    "Did not expect to find #{tag} in #{nodeset.to_xml}"
  end
end

def outermost_missing_tag_message(doc, tag, orig_tag=nil)
  return outermost_missing_tag_message(doc, tag.split("/"), tag) unless tag.is_a? Array
  return "Could not find any part of #{orig_tag} in document" if tag.empty?
  search_path = (tag.length > 1) ? "//#{tag[0..-2].join('/')}" : "//#{tag[0]}"
  nodeset_of_interest = doc.xpath(search_path)
  if (nodeset_of_interest).empty? && tag.length > 1
    outermost_missing_tag_message(doc, tag[0..-2], orig_tag)
  else
    xml_snippet = nodeset_of_interest.to_xml(:indent => 2)
    return "Searching for #{orig_tag}\nCould not find #{tag[0..-1].join('/')} in\n#{xml_snippet}"
  end
end

def check_node(node, attributes)
  return node.inner_text == attributes if attributes.is_a?(String)

  return false if attributes.has_key?(:_text) && node.inner_text != attributes[:_text]
  attributes.reject! { |k, _| k == :_text }

  return attributes.select { |k, v|
    node.attributes.fetch(k.to_s)&.value == v
  }.count == attributes.count
end


RSpec::Matchers.define :have_schema_location do |expected|

  match do |doc|
    schema_location = doc.xpath('/*').attr('xsi:schemaLocation')
    schema_location && schema_location.value == expected
  end

  failure_message do |doc|
    "Expected document's schema location to be #{expected}"
  end
end


RSpec::Matchers.define :have_namespaces do |expected|

  match do |doc|
    actual = doc.namespaces
    if actual.size > expected.size
      difference = actual.to_a - expected.to_a
    else
      difference = expected.to_a - actual.to_a
    end

    diff = Hash[*difference.flatten]

    diff.empty?
  end

  failure_message do |doc|
    "Expected document to have namespaces #{expected.inspect}, not #{doc.namespaces.inspect}"
  end
end
