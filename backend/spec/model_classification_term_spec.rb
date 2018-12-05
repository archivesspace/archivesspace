require 'spec_helper'

describe 'Classification models' do
  
  describe "slug tests" do
    it "autogenerates a slug via title when configured to generate by name" do
      AppConfig[:auto_generate_slugs_with_id] = false 

      ct = ClassificationTerm.create_from_json(build(:json_classification_term))
      ct_rec = ClassificationTerm.where(:id => ct[:id]).first.update(:is_slug_auto => 1)

      expected_slug = ct_rec[:title].gsub(" ", "_")
                                    .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")

      expect(ct_rec[:slug]).to eq(expected_slug)
    end

    it "autogenerates a slug via identifier when configured to generate by id" do
      AppConfig[:auto_generate_slugs_with_id] = true

      ct = ClassificationTerm.create_from_json(build(:json_classification_term))
      ct_rec = ClassificationTerm.where(:id => ct[:id]).first.update(:is_slug_auto => 1)
      
      expected_slug = ct_rec[:identifier].gsub(" ", "_")
                                         .gsub(/[&;?$<>#%{}|\\^~\[\]`\/@=:+,!]/, "")
                                         .gsub('"', '')
                                         .gsub('null', '')

      expect(ct_rec[:slug]).to eq(expected_slug)
    end
  end


end
