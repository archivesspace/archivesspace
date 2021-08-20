module Arks

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, extra_values = {}, apply_nested_records = true)
    ArkName.ensure_ark_for_record(self)

    super
  end

  module ClassMethods

    def create_from_json(json, extra_values = {})
      obj = super
      ArkName.ensure_ark_for_record(obj)
      obj
    end

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      fk_col = ArkName.fk_for_class(self)

      rec_ids_to_ark_obj = ArkName.filter(fk_col => objs.map(&:id))
                            .map {|ark_obj| [ark_obj[fk_col], ark_obj]}
                            .to_h

      objs.zip(jsons).each do |obj, json|
        ark_obj = rec_ids_to_ark_obj.fetch(obj.id, nil)

        if ark_obj
          json['ark_name'] = {
            'current_ark' => (ark_obj.user_value || ArkName.prefix(ark_obj.generated_value))
          }
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
