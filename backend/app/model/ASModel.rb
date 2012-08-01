module ASModel
  include JSONModel

  def before_create
    self.create_time = Time.now
    self.last_modified = Time.now
  end


  def before_update
    self.last_modified = Time.now
  end


  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json)
    self.update(self.class.map_references(json))
  end


  module ClassMethods

    def reference_to_id(ref)
      if ref =~ /\/([0-9]+)$/
        return $1
      else
        # This shouldn't happen: the JSON model should have already validated the
        # syntax of each reference.
        raise "Invalid reference: '#{ref}'"
      end
    end


    def references_map
      {
        "repository" => :repo_id,
        "collection" => nil,
        "parent" => nil
      }
    end


    def map_references(json)
      row = json.to_hash

      if self.respond_to? :references_map
        self.references_map.each do |reference, column|
          if column and row[reference]
            row[column] = reference_to_id(row[reference])
          end

          row.delete(reference)
        end
      end

      row
    end


    def create_from_json(json)
      self.create(map_references(json))
    end


    def get_or_die(id)
      # For a minute there I lost myself...
      self[id] or raise NotFoundException.new("#{self} not found")
    end
  end
end
