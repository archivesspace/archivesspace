# Store a set of directional dependencies in a reasonably memory-efficient way.
#
# We effectively want a structure like:
#
#  {
#    '/this/uri' (depends_on) => ['/that/uri', '/and/also/that/uri'],
#     ...
#  }
#
# But that's a lot of duplicated strings in memory when you're doing migrations
# of 1.5 million+ dependencies.
#
# So, we effectively "intern" the strings by giving each one an index, and then
# just store the index numbers in our dependency table.  On the large data set
# I'm testing with, that reduces the memory needed by about 80%.  Callers never
# see the indexes--they just pass record URIs in and get record URIs out.
#

class DependencySet

  def initialize
    # Mappings from strings to their indexes and back again
    @key_to_index = {}
    @index_to_key = []

    # Our list of dependencies, where @dependencies[123] is the array of record
    # indexes that record with index 123 depends on.
    @dependencies = []

    # The next index we'll allocate
    @next_index = 0
  end

  # The number of edges in our dependency graph
  def length
    @dependencies.map {|elt| elt ? elt.length : 0}.reduce(0) {|sum, n| sum + n}
  end

  # The record identifiers that have a dependency on something else.  That is,
  # the set of `froms` given to `add_dependency`.
  def keys
    result = @dependencies.each_with_index.map {|depends_on, index|
      if depends_on
        @index_to_key.fetch(index)
      end
    }
    result.compact!

    result
  end

  # Add a dependency between from one record identifier to another
  def add_dependency(from, to)
    from_idx = index_for(from)
    to_idx = index_for(to)

    @dependencies[from_idx] ||= []
    @dependencies[from_idx] << to_idx
  end

  # Get the list of records that record `key` depends on
  def [](key)
    key_index = index_for(key)

    Array(@dependencies[key_index]).map {|dependency_idx| @index_to_key.fetch(dependency_idx)}.freeze
  end

  private

  # Intern a string
  def index_for(key)
    unless @key_to_index.has_key?(key)
      @key_to_index[key] = @next_index
      @index_to_key[@next_index] = key

      @next_index += 1
    end

    @key_to_index.fetch(key)
  end

end
