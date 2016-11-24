class CycleFinder

  # Expects an instance of a DependencySet representing a dependency graph like:
  #
  #  {
  #      '/uri/1' => ['/uri/2', '/uri/3'],
  #      '/uri/2' => ['/uri/1', '/uri/4']
  #  }
  def initialize(graph, ticker)
    @graph = graph
    @ticker = ticker
    @whitelisted_nodes = {}

    @ticker.tick_estimate = @graph.keys.length
  end

  # Yields each URI involved in a cycle as we find them
  def each
    cycles_found = []

    @graph.keys.each do |start_node|
      @ticker.tick
      next if cycles_found.include?(start_node)

      find_cycles(start_node).each do |cycle|
        unless cycles_found.include?(cycle.node)
          cycles_found << cycle.node
          yield cycle.node
        end
      end
    end
  end

  private


  # Find all cycles in our graph beginning from `start_node`.
  def find_cycles(start_node)
    work_queue = [{:action => :check_node, :path => Path.new(start_node)}]
    cycles_found = []

    while !work_queue.empty?
      task = work_queue.shift

      if task[:action] == :whitelist_node
        # We've checked all children of this node, so it's acyclic and doesn't
        # need to be checked again.
        @whitelisted_nodes[task[:node]] = true
        next
      end

      # Otherwise, we're being asked to check a node
      task[:action] == :check_node or raise "Not sure what to do with #{task}"

      path_to_check = task[:path]

      if path_to_check.contains_cycle?
        # Found one!
        cycles_found << path_to_check
        next
      elsif @whitelisted_nodes[path_to_check.node]
        # We've visited this node before, so no need to recheck it
        next
      end

      # Once this node's dependencies have been checked, we can whitelist this
      # node to avoid further checking.  Since we're doing a depth-first search,
      # we add the whitelist action first.
      work_queue.unshift({:action => :whitelist_node, :node => path_to_check.node})

      # Add this node's dependencies to our list of nodes to check
      Array(@graph[path_to_check.node]).each do |dependency|
        work_queue.unshift({:action => :check_node,
                            :path => path_to_check.next_node(dependency)})
      end
    end

    cycles_found
  end

  # A path is a node plus the sequence of ancestor nodes we followed to get
  # there.  A path contains a cycle if the current node also appears in the
  # sequence of ancestors (meaning we doubled back)
  class Path
    attr_reader :node, :ancestors

    def initialize(node, ancestors = [])
      @node = node
      @ancestors = ancestors
    end

    def contains_cycle?
      ancestors.include?(node)
    end

    def next_node(new_node)
      self.class.new(new_node, ancestors + [node])
    end
  end

end
