require 'securerandom'
require_relative 'auto_generator'

module Notes

  def self.included(base)
    base.one_to_many :note

    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    self.class.apply_notes(obj, json)
  end



  module ClassMethods


    def populate_persistent_ids(json)
      json.notes.each do |note|
        JSONSchemaUtils.map_hash_with_schema(note, JSONModel(note['jsonmodel_type']).schema,
                                             [proc {|hash, schema|
                                                if schema['properties']['persistent_id']
                                                  hash['persistent_id'] ||= SecureRandom.hex
                                                end

                                                hash
                                              }])
      end
    end


    def apply_notes(obj, json)
      obj.note_dataset.delete

      populate_persistent_ids(json)


      json.notes.each do |note|
        publish = note['publish'] ? 1 : 0
        note.delete('publish')

        note_obj = Note.create(:notes_json_schema_version => json.class.schema_version,
                               :publish => publish,
                               :lock_version => 0,
                               :notes => JSON(note))

        obj.add_note(note_obj)
      end

      obj
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_notes(obj, json)
    end


    def sequel_to_jsonmodel(obj, opts = {})
      notes = Array(obj.note.sort_by {|note| note[:id]}).map {|note|
        parsed = ASUtils.json_parse(note.notes)
        parsed['publish'] = (note.publish == 1)
        parsed
      }

      json = super

      if obj.class.respond_to?(:node_record_type)
        klass = Kernel.const_get(obj.class.node_record_type.camelize)
        # If the object doesn't have a root record, it IS a root record.
        root_id = obj.respond_to?(:root_record_id) ? obj.root_record_id : obj.id

        notes.map { |note|
          if note["jsonmodel_type"] == "note_index"
            note["items"].map { |item|
              referenced_record = klass.filter(:root_record_id => root_id,
                                              :ref_id => item["reference"]).first
              if !referenced_record.nil?
                item["reference_ref"] = {"ref" => referenced_record.uri}
              end
            }
          end
        }
      end

      json.notes = notes

      json
    end


    def calculate_object_graph(object_graph, opts = {})
      super

      column = "#{self.table_name}_id".intern

      ids = Note.filter(column => object_graph.ids_for(self)).
                 map {|row| row[:id]}

      object_graph.add_objects(Note, ids)
    end

  end
end
