RSpec::Matchers.define :have_node do |path|
  match do |actual|
    if actual.at(path)
      true
    else
      false
    end
  end
  failure_message_for_should do |actual|
    prefix = ""
    while path.slice(0) == '/'
      prefix << path.slice!(0)
    end
    root_frags = path.split('/').reject{|f| f.empty?}
    node_frags = []
    matched_node = nil
    while(matched_node.nil? && root_frags.length > 1)
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
  failure_message_for_should_not do |actual|
    "Expected that #{actual} would not have node #{path}."
  end
  description do
    "have node: #{expected}"
  end
end


RSpec::Matchers.define :have_attribute do |att, val|
  match do |node|
    if val
      node.attr(att) && node.attr(att) == val
    else
      node.attr(att)
    end
  end

  failure_message_for_should do |node|
    if val and node.attr(att)
      "Expected '#{node.name}/@#{att}' to be '#{val}', not '#{node.attr(att)}'."
    else
      "Expected the node '#{node.name}' to have the attribute '#{att}'."
    end
  end

  failure_message_for_should_not do |node|
    "Unexpected attribute '#{att}' on node '#{node.name}'."
  end
end


RSpec::Matchers.define :have_inner_text do |expected|
  regex_mode = expected.is_a?(Regexp)

  match do |node|
    if regex_mode
      node.inner_text =~ expected
    else
      node.inner_text == expected
    end
  end

  failure_message_for_should do |node|
    infinitive = regex_mode ? "match /#{expected}/" : "contain '#{expected}'"
    "Expected node '#{node.name}' to #{infinitive}. Found string: '#{node.inner_text}'."
  end

  failure_message_for_should_not do |node|
    "Expected node '#{node.name}' to contain something other than '#{txt}'."
  end
end