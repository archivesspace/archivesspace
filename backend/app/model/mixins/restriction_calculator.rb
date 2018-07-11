module RestrictionCalculator

  def self.included(base)
    base.extend(ClassMethods)
  end


  def restrictions
    models_supporting_rights_restrictions = RightsRestriction.applicable_models.values

    models_supporting_rights_restrictions.map {|model|
      instance_link_column = model.association_reflection(:instance)[:key]

      id_set = TopContainer.linked_instance_ds.
               filter(:top_container__id => self.id).
               where { Sequel.~(instance_link_column => nil) }.
               select(instance_link_column).
               map {|row| row[instance_link_column]}

      model_to_record_ids = Implementation.expand_to_tree(model, id_set)

      model_to_record_ids.map {|restriction_model, restriction_ids|
        restriction_link_column = restriction_model.association_reflection(:rights_restriction)[:key]
        RightsRestriction.filter(restriction_link_column => restriction_ids).all
      }
    }.flatten.uniq(&:id)
  end


  def active_restrictions(clock = Date)
    now = clock.today

    restrictions.select {|restriction|
      if restriction.begin && now < restriction.begin
        false
      elsif restriction.end && now > restriction.end
        false
      elsif restriction.rights_restriction_type.empty? && restriction.begin.nil? && restriction.end.nil?
        false
      else
        true
      end
    }
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      unless opts[:skip_restrictions]
        jsons.zip(objs).each do |json, obj|
          json['active_restrictions'] = obj.active_restrictions.map {|restriction|
            RightsRestriction.to_jsonmodel(restriction)
          }
          json['restricted'] = !json['active_restrictions'].empty?
        end
      end

      jsons
    end

  end



  module Implementation

    def self.expand_to_tree(model, id_set)
      return {model => id_set} unless  model.included_modules.include?(TreeNodes)

      rec_ids = id_set
      new_rec_ids = rec_ids

      while true
        new_rec_ids = model.filter(:id => new_rec_ids).select(:parent_id).map(&:parent_id).compact

        if new_rec_ids.empty?
          break
        else
          rec_ids += new_rec_ids
        end
      end

      rec_ids = rec_ids.uniq

      {
        model => rec_ids,
        model.root_model => model.filter(:id => rec_ids).select(:root_record_id).distinct.map(&:root_record_id)
      }
    end

  end
end
