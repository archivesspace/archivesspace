class CollectionManagement < Sequel::Model(:collection_management)
  include ASModel
  include ExternalIDs

  set_model_scope :repository
  corresponds_to JSONModel(:collection_management)


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      parent_uri = if obj.resource_id
                     JSONModel(:resource).uri_for(obj.resource_id, :repo_id => active_repository)
                   elsif obj.digital_object_id
                     JSONModel(:digital_object).uri_for(obj.digital_object_id, :repo_id => active_repository)
                   elsif obj.accession_id
                     JSONModel(:accession).uri_for(obj.accession_id, :repo_id => active_repository)
                   end

      if parent_uri
        json['parent'] = {
          'ref' => parent_uri
        }
      end
    end

    jsons
  end

end
