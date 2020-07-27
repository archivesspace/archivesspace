class AgentRelationshipParentchild < Sequel::Model(:agent_relationship_parentchild)

  include ASModel
  corresponds_to JSONModel(:agent_relationship_parentchild)

  # include(Relationships)

  # How would this relationship know that the FK to use is related_agent_rlshp.id?
  # fails with: Exception (Unknown response: {"error":"method places= doesn't exist: /Users/manny/Dropbox/code/macCode/LibraryHost/archivesspace/build/gems/gems/sequel-4.20.0/lib/sequel/model/base.rb:2138:
  # tried 
  #define_relationship(:name => :subject,
  #                    :json_property => 'places',
  #                    :contains_references_to_types => proc {[Subject]})


end
