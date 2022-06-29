module RightsRestrictionNotes

  RESTRICTION_NOTE_TYPES = ['accessrestrict', 'userestrict']


  def self.included(base)
    base.extend(ClassMethods)

    base.one_to_many(:rights_restriction)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    obj = super
    RightsRestrictionNotes::Implementation.process_restriction_notes(json, obj)
    obj
  end


  module ClassMethods

    def create_from_json(json, opts = {})
      obj = super
      RightsRestrictionNotes::Implementation.process_restriction_notes(json, obj)
      obj
    end

    def handle_delete(ids)
      join_column = self.association_reflection(:rights_restriction)[:key]
      RightsRestriction.filter(join_column => ids).delete

      super
    end

  end


  module Implementation

    def self.process_restriction_notes(json, obj)
      obj.rights_restriction_dataset.delete

      restrictions = ASUtils.wrap(json['notes']).each do |note|
        next unless note['jsonmodel_type'] == 'note_multipart' && RESTRICTION_NOTE_TYPES.include?(note['type'])
        next unless note.has_key?('rights_restriction')

        restriction = obj.add_rights_restriction(:begin => note['rights_restriction']['begin'],
                                                 :end => note['rights_restriction']['end'],
                                                 :restriction_note_type => note['type'])

        ASUtils.wrap(note['rights_restriction']['local_access_restriction_type']).each do |restriction_type|
          restriction.add_rights_restriction_type(:restriction_type => restriction_type)
        end
      end
    end

  end


end
