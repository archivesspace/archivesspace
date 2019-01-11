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

   describe "slug code does not run" do
      it "does not execute slug code when auto-gen on id and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
  
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => true}))

        expect(classification).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)
  
        classification.update(:title => "foobar")
      end

      it "does not execute slug code when auto-gen on title and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false
  
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => true}))
  
        expect(classification).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)
  
        classification.update(:identifier => "foobar")
      end
  
      it "does not execute slug code when auto-gen off and title, identifier changed" do
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => false}))
  
        expect(classification).to_not receive(:auto_gen_slug!)
        expect(SlugHelpers).to_not receive(:clean_slug)
  
        classification.update(:identifier => "foobar")
        classification.update(:title => "barfoo")
      end
    end

    describe "slug code runs" do
      it "executes slug code when auto-gen on id and id is changed" do
        AppConfig[:auto_generate_slugs_with_id] = true
  
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => true}))
  
        expect(classification).to receive(:auto_gen_slug!)
        
        #pending("no idea why this is failing. Testing this manually in app works as expected")
  
        classification.update(:identifier => 'foo')
      end

      it "executes slug code when auto-gen on title and title is changed" do
        AppConfig[:auto_generate_slugs_with_id] = false
  
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => true}))
  
        expect(classification).to receive(:auto_gen_slug!)
  
        classification.update(:title => "foobar")
      end

      it "executes slug code when autogen is turned on" do
        AppConfig[:auto_generate_slugs_with_id] = false
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => false}))
  
        expect(classification).to receive(:auto_gen_slug!)
  
        classification.update(:is_slug_auto => 1)
      end

      it "executes slug code when autogen is off and slug is updated" do
        classification = ClassificationTerm.create_from_json(build(:json_classification_term, {:is_slug_auto => false}))
  
        expect(SlugHelpers).to receive(:clean_slug)
  
        classification.update(:slug => "snow white")
      end
    end
  end
end
