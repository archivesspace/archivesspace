# FIXME: custom validation for dates, etc.?


module RightsRestrictionNotes

  RESTRICTION_NOTE_TYPES = ['accessrestrict', 'userestrict']

     # [java] D, [2015-03-17T13:22:45.092000 #26783] DEBUG -- : Thread-3540: POST /repositories/2/resources/3 [session: #<Session:0x67d6b87e @store={:user=>"admin", :login_time=>2015-03-17 13:05:09 +1100, :expirable=>true}, @id="7417bad2ee8e2e27b26a12707817334b99d69b50e604e507ce3bee560d354d37">]
     # [java] D, [2015-03-17T13:22:45.149000 #26783] DEBUG -- : Thread-3540: Post-processed params: {:id=>3, :resource=>#<JSONModel(:resource) {"lock_version"=>"0", "title"=>"moo", "id_0"=>"123", "id_1"=>"f", "level"=>"file", "language"=>"eng", "dates"=>[{"lock_version"=>"0", "label"=>"creation", "expression"=>"moooo", "date_type"=>"single", "begin"=>"2015-03-04"}], "extents"=>[{"lock_version"=>"0", "portion"=>"whole", "number"=>"10", "extent_type"=>"leaves"}], "notes"=>[{"jsonmodel_type"=>"note_multipart", "persistent_id"=>"56de90dad4c61995a2cb65b9e8439f92", "type"=>"accessrestrict", "rights_restriction"=>{"begin"=>"2000-01-01", "end"=>"2005-01-01", "local_access_restriction_type"=>["RestrictedCurApprSpecColl"]}, "subnotes"=>[{"jsonmodel_type"=>"note_text", "content"=>"moo", "publish"=>false}], "publish"=>false}], "publish"=>false, "restrictions"=>false, "jsonmodel_type"=>"resource", "external_ids"=>[], "subjects"=>[], "external_documents"=>[], "rights_statements"=>[], "linked_agents"=>[], "instances"=>[], "deaccessions"=>[], "related_accessions"=>[], "linked_events"=>[]}>, :repo_id=>2}


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

        begin_date = note['rights_restriction']['begin'] ? Date.parse(note['rights_restriction']['begin']) : nil
        end_date = note['rights_restriction']['end'] ? Date.parse(note['rights_restriction']['end']) : nil

        restriction = obj.add_rights_restriction(:begin => begin_date,
                                                 :end => end_date,
                                                 :restriction_note_type => note['type'])

        ASUtils.wrap(note['rights_restriction']['local_access_restriction_type']).each do |restriction_type|
          restriction.add_rights_restriction_type(:restriction_type => restriction_type)
        end
      end
    end

  end


end
