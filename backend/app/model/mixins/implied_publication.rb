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

          referrer_columns.each do |referrer_column|
            reference_columns.each do |reference_column|
              relationship_class.join(related_class, :id => referrer_column).
                filter(:publish => 1).
                filter(reference_column => obj_ids).
                select(reference_column).
                each do |published|
                result[published[reference_column]] = true
              end
            end
          end
        end
      end

      result
    end

  end

end
