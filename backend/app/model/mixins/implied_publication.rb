module ImpliedPublication

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      published_by_implication = find_published_by_implication(objs)

      jsons.zip(objs).each do |json, obj|
        json.is_linked_to_published_record = published_by_implication.fetch(obj.id, false)
      end

      jsons
    end

    # Return a map of obj.id => boolean, indicating whether that (subject or
    # agent) record is published by virtue of being linked to a published
    # archival record.
    def find_published_by_implication(objs)
      result = {}
      obj_ids = objs.map(&:id)

      self.relationship_dependencies.each do |relationship_name, relationship_dependency|

        # Limit to the record types that link to us
        next unless [:subject, :linked_agents].include?(relationship_name)

        relationship_dependency.each do |related_class|

          # If the record type doesn't have a notion of being published, we don't care about it
          next unless related_class.columns.include?(:publish)

          break if obj_ids.all? {|id| result.has_key?(id)}

          relationship_class = related_class.find_relationship(relationship_name, true)
          reference_columns = relationship_class.reference_columns_for(self)
          referrer_columns = relationship_class.reference_columns_for(related_class)


          if related_class.included_modules.include?(TreeNodes)
            # need work up the tree and check each level is published and not suppressed
            referrer_columns.each do |referrer_column|
              reference_columns.each do |reference_column|
                obj_id_to_node_id = {}
                published_nodes = {}
                unpublished_nodes = []

                relationship_class.join(related_class, :id => referrer_column)
                  .filter(Sequel.qualify(related_class.table_name, :publish) => 1)
                  .filter(Sequel.qualify(related_class.table_name, :suppressed) => 0)
                  .filter(reference_column => obj_ids)
                  .select(Sequel.as(Sequel.qualify(relationship_class.table_name, reference_column), :id),
                          Sequel.as(Sequel.qualify(relationship_class.table_name, referrer_column), :node_id),
                          Sequel.as(Sequel.qualify(related_class.table_name, :parent_id), :parent_id),
                          Sequel.as(Sequel.qualify(related_class.table_name, :root_record_id), :root_record_id))
                  .each do |row|

                  obj_id_to_node_id[row[:id]] ||= []
                  obj_id_to_node_id[row[:id]] << row[:node_id]
                  published_nodes[row[:node_id]] = row[:parent_id]
                end

                parent_ids = published_nodes.values.compact

                while(true)
                  next_parent_ids = []

                  related_class
                    .filter(:id => parent_ids)
                    .select(:id, :parent_id, :suppressed, :publish)
                    .each do |row|
                    if row[:suppressed] == 1 || row[:publish] == 0
                      unpublished_nodes << row[:id]
                    else
                      published_nodes[row[:id]] = row[:parent_id]
                      next_parent_ids << row[:parent_id]
                    end
                  end

                  break if next_parent_ids.compact.empty?

                  parent_ids = next_parent_ids
                end

                published = published_nodes.reject {|k, v| unpublished_nodes.include?(k) || unpublished_nodes.include?(v)}.keys

                related_class
                  .join(related_class.root_model.table_name, :id => :root_record_id)
                  .filter(Sequel.qualify(related_class.table_name, :id) => published)
                  .filter(Sequel.qualify(related_class.root_model.table_name, :suppressed) => 0)
                  .filter(Sequel.qualify(related_class.root_model.table_name, :publish) => 1)
                  .select(Sequel.as(Sequel.qualify(related_class.table_name, :id), :id))
                  .each do |row|
                  obj_id_to_node_id.each do |obj_id, node_ids|
                    if node_ids.include?(row[:id])
                      result[obj_id] = true
                    end
                  end
                end
              end
            end
          else
            referrer_columns.each do |referrer_column|
              reference_columns.each do |reference_column|
                relationship_class.join(related_class, :id => referrer_column).
                  filter(:publish => 1).
                  filter(Sequel.qualify(related_class.table_name, :suppressed) => 0).
                  filter(reference_column => obj_ids).
                  select(reference_column).
                  each do |published|
                  result[published[reference_column]] = true
                end
              end
            end
          end
        end
      end

      result
    end

  end

end
