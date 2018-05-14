class Accession < Sequel::Model(:accession)
  include ASModel
  corresponds_to JSONModel(:accession)

  include Identifiers
  include Extents
  include Subjects
  include Dates
  include ExternalDocuments
  include RightsStatements
  include Deaccessions
  include Agents
  include DirectionalRelationships
  include ExternalIDs
  include CollectionManagements
  include Instances
  include UserDefineds
  include Classifications
  include AutoGenerator
  include Transferable
  include Events
  include Publishable
  include ReindexTopContainers
  include Assessments::LinkedRecord
  
  agent_role_enum("linked_agent_role")
  agent_relator_enum("linked_agent_archival_record_relators")

  enable_suppression
  set_model_scope :repository


  define_relationship(:name => :spawned,
                      :json_property => 'related_resources',
                      :contains_references_to_types => proc {[Resource]})


  define_directional_relationship(:name => :related_accession,
                                  :json_property => 'related_accessions',
                                  :contains_references_to_types => proc {[Accession]},
                                  :class_callback => proc {|clz|
                                    clz.instance_eval do
                                      include DynamicEnums
                                      uses_enums({
                                                   :property => 'relator',
                                                   :uses_enum => ['accession_parts_relator', 'accession_sibling_relator']
                                                 },
                                                 {
                                                   :property => 'relator_type',
                                                   :uses_enum => ['accession_parts_relator_type', 'accession_sibling_relator_type']
                                                 })
                                    end
                                  })


  auto_generate :property => :display_string,
                :generator => lambda { |json|
                  return json["title"] if json["title"]

                  %w(id_0 id_1 id_2 id_3).map{|p| json[p]}.compact.join("-")
                }

  # If we have an ID in any of the ID fields for a resource that looks like an ARK, 
  # update the external_id field in the linked ARKIdentifier record
  def after_save
    # self.identifier is a String representation of an array, like:
    # "[\"https://n2t.net/ark:/00001/f1mw5e\",null,null,null]"
    # We need to remove superflous charaters so we can turn it into an actual array.

    id_ary = self.identifier.gsub('[', "").gsub(']', "").gsub('"', '').split(",")

    id_ary.each do |i|
      if i =~ /ark:\//
        ark = ARKIdentifier.first(accession_id: self.id)
        ark.update(:external_id => i) if ark
      end
    end

    super
  end               
end
