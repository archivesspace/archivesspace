## Background
##
# This module implements the notion of "object graphs" for ArchivesSpace record
# types.  A record's object graph is the set of all records it is connected to.
# This can include:
#
#  * The nested records of a record (for example, the extent records of a Resource)
#
#  * The relationships a record participates in (for example, the linked agent
#    relationships connected to a Resource).  Note that this refers to the
#    relationship itself, not the record on the other side of the relationship.
#
#  * The parent/child relationships between records in a tree (for example, the
#    component records beneath a Resource or Digital Object)
#
# Object graphs are transitive: we calculate a record's object graph by adding
# its directly connected records to a set, then repeat that procedure for all
# records in the set until we can expand no further.  So, a record's object
# graph includes its friends, its friends-of-friends, and so on.
#
# Since these object graphs can be quite large, we represent them only as sets
# of record IDs (grouped by model type), rather than as fully realised records.
#

## What they're for
##
# There are several places in the ArchivesSpace data model where we want to
# perform some action on a record and everything connected to it.  Currently:
#
#  * We want to be able to say "Publish this record and everything connected to
#    it", and have that publish all nested records, components, notes and
#    relationships.
#
#  * Likewise, we want to be able to suppress a given record and do the same.
#
#  * We also need to support deletion, where records and all of their
#    dependencies are removed.
#
# Object graphs let us perform these actions with relatively small numbers of
# database updates, since we can update all matching records with one UPDATE per
# model, rather than one UPDATE per record.


## The Implementation
##
# Calculating the object graph for a record is kicked off by calling its
# .object_graph method.  This handles the logic of iteratively expanding the
# object graph until it reaches a fixed point.
#
# The object graph is expanded by calls to .calculate_object_graph on the record
# model itself.  Various mixins add their own behaviour by subclassing this
# method.  For example, the mixins for handling record trees can handle the
# .calculate_object_graph call by extracting the IDs of child records and adding
# them to the object graph.


require 'set'

module ObjectGraph

  def self.included(base)
    base.extend(ClassMethods)
  end


  class ObjectGraph

    def initialize(hash = {})
      @graph = Hash[hash.map {|model, ids|
                      [model, Set.new(ids)]
                    }]
    end

    def add_objects(model, *ids)
      flat_ids = ids.flatten
      return if flat_ids.empty?
      @graph[model] ||= Set.new
      @graph[model].merge(flat_ids)

      self
    end

    def version
      @graph.hash
    end

    def changed_since?(version)
      self.version != version
    end

    def ids_for(model)
      @graph[model] ? @graph[model].to_a : []
    end

    def each(&block)
      if block_given?
        @graph.keys.each do |model|
          block.call(model, @graph[model].to_a)
        end
      else
        Enumerator.new do |y|
          @graph.map {|model, ids|
            y << [model, ids.to_a]
          }
        end
      end
    end

    def models
      @graph.keys
    end

  end


  def object_graph(opts = {})
    graph = ObjectGraph.new(self.class => [self.id])

    while true
      version = graph.version

      graph.models.each do |model|
        model.calculate_object_graph(graph, opts)
      end

      break unless graph.changed_since?(version)
    end

    graph
  end


  module ClassMethods

    def calculate_object_graph(object_graph, opts = {})

      object_graph.models.each do |model|
        next unless model.respond_to?(:nested_records)
        model.nested_records.each do |nr|
          association =  nr[:association]

          if association[:type] != :many_to_many
            nested_model = Kernel.const_get(association[:class_name])

            ids = nested_model.filter(association[:key] => object_graph.ids_for(model)).
                               select(:id).map {|row|
              row[:id]
            }

            object_graph.add_objects(nested_model, ids)
          end
        end
      end

      object_graph
    end

  end

end
