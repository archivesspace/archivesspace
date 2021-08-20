module Arks

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, extra_values = {}, apply_nested_records = true)
    ArkName.ensure_ark_for_record(self, json)

    super
  end

  module ClassMethods

    def create_from_json(json, extra_values = {})
      obj = super
      ArkName.ensure_ark_for_record(obj, json)
      obj
    end

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
          current = arks.select{|ark| ark.is_current == 1}

          json['ark_name'] = {
            'current' => current.map{|ark| ark.user_value || ArkName.prefix(ark.generated_value)}.first,
            'previous' => arks.select{|ark| ark.is_current == 0}.map{|ark| ark.user_value || ArkName.prefix(ark.generated_value)},
          }

          json['external_ark_url'] = current.map{|ark| ark.user_value}.first
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
