require 'spec_helper'

describe 'Metadata Rights Declaration' do

  def publishable_record_types
    %w(resource accession agent_person agent_family agent_corporate_entity agent_software subject digital_object)
  end

  it 'appends persistently to any publishable record type' do
    publishable_record_types.each do |record_type|
      record_in = create("json_#{record_type}".to_sym,
                         :metadata_rights_declarations => [build(:json_metadata_rights_declaration)])
      klass = Kernel.const_get(record_type.camelize)
      record_out = klass.sequel_to_jsonmodel([klass[record_in.id]]).first
      expect(record_out.metadata_rights_declarations[0]["rights_statement"]).to eq "public_domain"
      expect(record_out.metadata_rights_declarations[0]["file_version_xlink_show_attribute"]).to eq "other"
    end
  end
end
