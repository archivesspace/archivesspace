module Arks

  def self.included(base)
    base.extend(ClassMethods)
  end

  # You'd think we'd put this in either create_from_json or update_from_json
  # but if we did we'd miss out on having our new ARK being indexed by the
  # realtime indexer via fire_update.  So instead, we "hook" ourselves into
  # apply_nested_records which conveniently happens before the fire_update.
  def apply_nested_records(json, new_record = false)
    super

    ArkName.ensure_ark_for_record(self, json['external_ark_url'])
  end

  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      fk_col = ArkName.fk_for_class(self)

      rec_ids_to_arks = {}

      ArkName.filter(fk_col => objs.map(&:id)).each do |ark_obj|
        rec_ids_to_arks[ark_obj[fk_col]] ||= []
        rec_ids_to_arks[ark_obj[fk_col]] << ark_obj
      end

      objs.zip(jsons).each do |obj, json|
        arks = rec_ids_to_arks.fetch(obj.id, [])

        unless arks.empty?
          (current, *), previous = arks.partition {|ark| ark.is_current == 1}

          json['ark_name'] = {
            'current' => current.value,
            'previous' => previous.map(&:value),
          }

          json['external_ark_url'] = current.user_value
        end
      end

      jsons
    end

    def handle_delete(ids_to_delete)
      ArkName.handle_delete(self, ids_to_delete)

      super
    end

  end


end
