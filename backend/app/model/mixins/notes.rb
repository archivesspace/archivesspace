require 'securerandom'
require_relative 'auto_generator'
require_relative 'publishable'
require_relative '../note'

module Notes

  def self.included(base)
    base.one_to_many :note

    Note.many_to_one base.table_name

    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    self.class.apply_notes(obj, json)
  end


  def persistent_id_context
    if self.respond_to?(:root_record_id) && self.root_record_id
      parent_id = self.root_record_id
      parent_type = self.class.root_record_type.to_s
    else
      parent_id = self.id
      parent_type = self.class.my_jsonmodel.record_type
    end

    [parent_id, parent_type]
  end


  module ClassMethods

    def handle_publish_flag(ids, val)
      super

      association = self.association_reflection(:note)
      SubnoteMetadata.filter(:note_id => Note.filter(association[:key] => ids).map(&:id)).
                      update(:publish => val ? 1 : 0)
    end


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


    def populate_metadata(note)
      metadata = []

      toplevel = true
      result = JSONSchemaUtils.map_hash_with_schema(note, JSONModel(note['jsonmodel_type']).schema,
                                                    [proc {|hash, schema|
                                                       if toplevel
                                                         toplevel = false
                                                         hash
                                                       elsif "#{hash['jsonmodel_type']}".start_with?('note_')
                                                         guid = SecureRandom.hex

                                                         metadata << {
                                                           :guid => guid,
                                                           :publish => Publishable.db_value_for(hash)
                                                         }

                                                         hash.merge('subnote_guid' => guid)
                                                       else
                                                         hash
                                                       end
                                                     }])

      [metadata, result]
    end


    def extract_persistent_ids(note)
      result = []

      JSONSchemaUtils.map_hash_with_schema(note, JSONModel(note['jsonmodel_type']).schema,
                                           [proc {|hash, schema|
                                              if schema['properties']['persistent_id']
                                                result << hash['persistent_id']
                                              end

                                              hash
                                            }])

      result.compact
    end


    def handle_delete(ids_to_delete)
      delete_subnote_metadata(ids_to_delete)
      super
    end

    def delete_subnote_metadata(ids_to_delete)
      association = self.association_reflection(:note)
      begin
        SubnoteMetadata.join(:note, Sequel.qualify(:note, :id) => Sequel.qualify(:subnote_metadata, :note_id))
          .filter( association[:key] => ids_to_delete ).delete
      rescue Sequel::InvalidOperation # for derby
        SubnoteMetadata.filter(:note_id => Note.filter(association[:key] => ids_to_delete).select(:id)).delete
      end
    end

    def apply_notes(obj, json)
      if obj.note_dataset.first
        delete_subnote_metadata([obj.id])
        obj.note_dataset.delete
      end
      populate_persistent_ids(json)

      json.notes.each do |note|
        metadata, note = populate_metadata(note)

        publish = note['publish'] ? 1 : 0
        note.delete('publish')

        note_obj = Note.create(:notes_json_schema_version => json.class.schema_version,
                               :publish => publish,
                               :lock_version => 0,
                               :notes => JSON(note))

        metadata.each do |m|
          SubnoteMetadata.create(:publish => m.fetch(:publish),
                                 :note_id => note_obj.id,
                                 :guid => m.fetch(:guid))
        end

        note_obj.add_persistent_ids(extract_persistent_ids(note),
                   *obj.persistent_id_context)

        obj.add_note(note_obj)
      end

      obj
    end


    def create_from_json(json, opts = {})
      obj = super
      apply_notes(obj, json)
    end


    def resolve_note_component_references(obj, json)
      if obj.class.respond_to?(:node_record_type)
        klass = Kernel.const_get(obj.class.node_record_type.camelize)
        # If the object doesn't have a root record, it IS a root record.
        root_id = obj.respond_to?(:root_record_id) ? obj.root_record_id : obj.id

        json.notes.each do |note|
          JSONSchemaUtils.map_hash_with_schema(note, JSONModel(note['jsonmodel_type']).schema,
                                               [proc {|hash, schema|
                                                  if hash['jsonmodel_type'] == 'note_index'
                                                    hash["items"].each do |item|
                                                      if item["reference"]
                                                        referenced_record = klass.filter(:root_record_id => root_id,
                                                                                         :ref_id => item["reference"]).first
                                                        if !referenced_record.nil?
                                                          item["reference_ref"] = {"ref" => referenced_record.uri}
                                                        end
                                                      end
                                                    end
                                                  end

                                                  hash
                                                }])
        end
      end
    end


    def resolve_note_persistent_id_references(obj, json, cache)
      json.notes.each do |note|
        JSONSchemaUtils.map_hash_with_schema(note, JSONModel(note['jsonmodel_type']).schema,
                                             [proc {|hash, schema|
                                                if hash['jsonmodel_type'] == 'note_index'
                                                  hash["items"].each do |item|
                                                    if item["reference"]
                                                      (parent_id, parent_type) = obj.persistent_id_context
                                                      persistent_id_records = {}
                                                      if cache.has_key?(parent_type) and cache[parent_type].has_key?(parent_id)
                                                        persistent_id_records = cache[parent_type][parent_id]
                                                      else
                                                        # query for these once per context and collect persistent_id => note_id
                                                        persistent_id_records = NotePersistentId.filter(
                                                          :parent_id => parent_id,
                                                          :parent_type => parent_type
                                                        ).each_with_object({}) do |pid, h|
                                                          h[pid.persistent_id] = pid.note_id
                                                        end
                                                        cache[parent_type][parent_id] = persistent_id_records
                                                      end

                                                      note_id = persistent_id_records[item["reference"]]

                                                      if !note_id.nil?
                                                        note = Note[note_id]

                                                        referenced_record = Note.associations.map {|association|
                                                          next if association == :note_persistent_id
                                                          note.send(association)
                                                        }.compact.first

                                                        if referenced_record
                                                          item["reference_ref"] = {"ref" => referenced_record.uri}
                                                        end
                                                      end
                                                    end
                                                  end
                                                end

                                                hash
                                              }])
      end
    end


    def resolve_note_references(obj, json, cache)
      resolve_note_component_references(obj, json)
      resolve_note_persistent_id_references(obj, json, cache)
    end


    def load_subnote_metadata(notes)
      note_ids = notes.values.flatten.map(&:id)

      # Avoid empty sequel `SELECT * FROM subnote_metadata WHERE note_id != note_id`
      # MySQL does not optimise such a query and this may lead to performance
      # degradation for databases with large numbers of notes.
      return {} if note_ids.empty?

      Hash[SubnoteMetadata.filter(:note_id => note_ids).
                           all.
                           map {|sm|
             [sm.guid, sm]
           }]
    end


    def apply_subnote_metadata(json, subnote_metadata)
      JSONSchemaUtils.map_hash_with_schema(json, JSONModel(json['jsonmodel_type']).schema,
                                           [proc {|hash, schema|
                                              if hash['subnote_guid']
                                                guid = hash['subnote_guid']
                                                hash['publish'] = (subnote_metadata[guid].publish == 1)
                                                hash.delete('subnote_guid')
                                              end

                                              hash
                                            }])

      json
    end


    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      # Avoid empty sequel `SELECT * FROM note WHERE association[:key] != association[:key]`
      # when there are no objs. This can happen when the primary record is not
      # linked to any nested record objects that use this mixin e.g. an
      # accession with no rights statements.  MySQL does not optimise such a
      # query and this may lead to performance degradation for databases with
      # large numbers of notes.
      return jsons if objs.empty?

      association = self.association_reflection(:note)
      notes = {}

      # we'll use this to store note_persistent_id data (by parent type and id)
      # reducing the no. of db queries which can be a problem when there are many
      # persistent id references associated with a parent type + id
      persistent_id_cache = Hash.new { |hash, key| hash[key] = {} }

      Note.filter(association[:key] => objs.map(&:id)).map {|note|
        record_id = note[association[:key]]
        notes[record_id] ||= []
        notes[record_id] << note
      }

      subnote_metadata = load_subnote_metadata(notes)

      jsons.zip(objs).each do |json, obj|
        my_notes = Array(notes[obj.id]).sort_by(&:id).map {|note|
          parsed = ASUtils.json_parse(note.notes)

          apply_subnote_metadata(parsed, subnote_metadata)

          parsed['publish'] = (note.publish == 1)
          parsed
        }

        json.notes = my_notes

        resolve_note_references(obj, json, persistent_id_cache)
      end
      persistent_id_cache = nil

      jsons
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
