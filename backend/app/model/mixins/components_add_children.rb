require_relative 'tree_nodes'

module ComponentsAddChildren

  def self.included(base)
    if not base.included_modules.include?(TreeNodes)
      base.extend(ClassMethods)
    end
  end

  def add_children(children)
    children.children.each do |child|
      obj = JSONModel(self.class.node_record_type.intern).from_hash(child)

      root_model = Kernel.const_get(self.class.root_record_type.camelize)
      node_model = Kernel.const_get(self.class.node_record_type.camelize)


      if root_model == self.class
        obj[self.class.root_record_type] = {
          'ref' => self.uri
        }
      else
        obj[self.class.root_record_type] = {
          'ref' => self.class.uri_for(self.class.root_record_type, self[:root_record_id])
        }

        obj['parent'] = {
          'ref' => self.uri
        }
      end

      begin
        node_model.create_from_json(obj)
      rescue Sequel::ValidationFailed => e
        # We've run into something that the DB doesnt like.
        # since we are dealing with a batch, we can add the
        # offending value to the error message in an attempt
        # to enlighten our  user
        e.errors.keys.each do |key|
          next unless obj[key]
          e.errors[key].map! { |msg| msg << " ( #{key}: #{obj[key]} )"}
        end
        raise e
      end
    end
  end


  module ClassMethods

    def tree_record_types(root, node)
      @root_record_type = root.to_s
      @node_record_type = node.to_s
    end

    def root_record_type
      @root_record_type
    end

    def node_record_type
      @node_record_type
    end

  end

end
