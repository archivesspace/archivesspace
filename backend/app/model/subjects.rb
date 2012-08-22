# Handling for models that require Subjects

module Subjects


   def self.included(base)
      base.many_to_many :subjects
      base.extend(ClassMethods)
   end


   def update_from_json(json, opts = {})
     obj = super(json, opts)
     self.class.apply_subjects(obj, json, {})
     obj
   end


   module ClassMethods

      def apply_subjects(obj, json, opts)
        obj.remove_all_subjects

        (json.subjects or []).each do |uri|
          subject = Subject[JSONModel(:subject).id_for(uri)]
          if subject.nil?
            raise JSONModel::ValidationException.new(:errors => {
                                                       :subjects => ["No subject found for #{uri}"]
                                                     })
          else
            obj.add_subject(subject)
          end
        end
      end


      def create_from_json(json, opts = {})
        obj = super(json, opts)
        apply_subjects(obj, json, opts)
        obj
      end


      def sequel_to_jsonmodel(obj, type)
        json = super(obj, type)
        json.subjects = obj.subjects.map {|subject| JSONModel(:subject).uri_for(subject.id)}

        json
      end

   end


end
