class SAXXMLReader

  include Enumerable

  def initialize(source_xml)
    @source_xml = source_xml
  end

  def each(&block)
    empty_node_indexes = Set.new

    # First pass: calculate our empty node indexes.  A node is empty if it has no
    # children, or if all of its children are blank text nodes or comments.
    maybe_empty = []

    inner_reader.each_with_index do |node, i|
      ignorable = (
        (node.node_type == Nokogiri::XML::Reader::TYPE_COMMENT) ||
        (node.node_type == Nokogiri::XML::Reader::TYPE_WHITESPACE) ||
        (node.node_type == Nokogiri::XML::Reader::TYPE_SIGNIFICANT_WHITESPACE) ||
        (node.node_type == Nokogiri::XML::Reader::TYPE_TEXT && node.value !~ /\S/) ||
        (node.node_type == Nokogiri::XML::Reader::TYPE_CDATA && node.value !~ /\S/)
      )

      # This element doesn't count towards making its containing element non-empty
      next if ignorable

      # Otherwise, any "maybe empty" elements with a depth less than this
      # (i.e. further up in the tree) are not empty.
      while maybe_empty.length > 0 && maybe_empty.last[:depth] < node.depth
        maybe_empty.pop
      end

      if maybe_empty.length > 0 && maybe_empty.last[:depth] <= node.depth
        # Either this is a closer for our pending element, or the original element was
        # self-closing.  Either way, if it's still sitting in `maybe_empty`, it must
        # have been empty.
        empty_node_indexes << maybe_empty.pop[:index]
      end

      # We'll need to keep checking to work out if this one is empty.
      if node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        maybe_empty << {index: i, depth: node.depth}
      end
    end

    # Second pass: iterate the same nodes and indicate which ones are empty to the
    # caller.
    inner_reader.each_with_index do |node, i|
      block.call(node, empty_node_indexes.include?(i))
    end
  end

  private

  def inner_reader
    reader = Nokogiri::XML::Reader(@source_xml) do |config|
      config.noblanks.strict
    end

    InnerReaderWithNodeClearing.new(reader)
  end

  # Nokogiri under JRuby has historically had problems where all nodes are loaded
  # into memory.  We do some footwork here to clear the nodes as we finish with
  # them, allowing the GC to clean up as we go.
  #
  # As of 2021, this still looks to be relevant:
  #
  # https://github.com/sparklemotion/nokogiri/issues/1066
  #
  InnerReaderWithNodeClearing = Struct.new(:reader, :node_queue) do
    def initialize(reader)
      self.reader = reader

      # Java reflection to get at Nokogiri's internal node queue.
      obj = reader.to_java
      nodeQueueField = obj.get_class.get_declared_field("nodeQueue")
      nodeQueueField.setAccessible(true)
      self.node_queue = nodeQueueField.get(obj)
    end

    def each(&block)
      i = 0

      self.reader.each do |node|
        block.call(node)
        self.node_queue.set(i, nil)
        i += 1
      end
    end
  end
end
