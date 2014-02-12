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


  def object_graph
    graph = ObjectGraph.new(self.class => [self.id])

    while true
      version = graph.version
      self.class.calculate_object_graph(graph)
      break unless graph.changed_since?(version)
    end

    graph
  end


  module ClassMethods

    def calculate_object_graph(object_graph)
      self.nested_records.each do |nr|
        association =  nr[:association]
        nested_model = Kernel.const_get(association[:class_name])

        ids = nested_model.filter(association[:key] => object_graph.ids_for(self)).
                           select(:id).map {|row|
          row[:id]
        }

        object_graph.add_objects(nested_model, ids)
      end

      object_graph
    end

  end

end
