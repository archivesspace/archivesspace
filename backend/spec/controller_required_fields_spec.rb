require_relative 'spec_helper'
require_relative 'spec_slugs_helper'

describe 'Required Fields' do

  it "lets you post and fetch a requirements definition for a repository and record type" do
   uri = "/repositories/#{$repo_id}/required_fields/agent_person"
   url = URI("#{JSONModel::HTTP.backend_url}#{uri}")
   required_fields = JSONModel(:required_fields).from_hash(
     {
       repo_id: $repo_id,
       record_type: "agent_person",
       subrecord_requirements: [
         {
           record_type: "metadata_rights_declaration",
           property: "metadata_rights_declarations",
           required: true,
           required_fields: ["xlink_title_attribute", "xlink_role_attribute"]
         }
       ]
     })
   response = JSONModel::HTTP.post_json(url, ASUtils.to_json(required_fields))
   expect(response.status).to eq(200)
   required_fields = JSONModel(:required_fields).fetch(uri)

    # requirements apply to this type of subrecord
   expect(required_fields["subrecord_requirements"].first["record_type"]).to eq("metadata_rights_declaration")
    # when it is occupying this property on the top-level record
   expect(required_fields["subrecord_requirements"].first["property"]).to eq("metadata_rights_declarations")
    # the top-level record requires that subrecords of this type have these fields
   expect(required_fields["subrecord_requirements"].first["required_fields"]).to eq(["xlink_title_attribute", "xlink_role_attribute"])
    # at least one subrecord is required
   expect(required_fields["subrecord_requirements"].first["required"]).to be true
 end
end
