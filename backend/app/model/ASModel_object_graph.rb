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


  def object_graph(opts = {})
    graph = ObjectGraph.new(self.class => [self.id])

    opts = {:include_nested => true}.merge(opts)

    while true
      version = graph.version
      self.class.calculate_object_graph(graph, opts)
      break unless graph.changed_since?(version)
    end

    graph
  end


  module ClassMethods

    def calculate_object_graph(object_graph, opts = {})

      if opts[:include_nested]
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
      end

      object_graph
    end

  end

end
