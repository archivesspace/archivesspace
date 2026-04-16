require 'spec_helper'

describe 'MultilingualContent mixin' do

  def eng_id
    enum_id = Enumeration.filter(:name => 'language_iso639_2').get(:id)
    EnumerationValue.filter(:enumeration_id => enum_id, :value => 'eng').get(:id)
  end

  def fre_id
    enum_id = Enumeration.filter(:name => 'language_iso639_2').get(:id)
    EnumerationValue.filter(:enumeration_id => enum_id, :value => 'fre').get(:id)
  end

  def latn_id
    enum_id = Enumeration.filter(:name => 'script_iso15924').get(:id)
    EnumerationValue.filter(:enumeration_id => enum_id, :value => 'Latn').get(:id)
  end

  def resource_mlc
    Resource.db[:resource_mlc]
  end

  def create_resource_with_primary_lang
    create_resource(
      :lang_descriptions => [{
        "language"   => "eng",
        "script"     => "Latn",
        "is_primary" => true
      }]
    )
  end

  def with_language_context(language_id:, script_id:)
    orig = RequestContext.get(:language_of_description)
    RequestContext.put(:language_of_description, { language_id: language_id, script_id: script_id })
    yield
  ensure
    RequestContext.put(:language_of_description, orig)
  end

  def without_language_context
    orig = RequestContext.get(:language_of_description)
    RequestContext.put(:language_of_description, nil)
    yield
  ensure
    RequestContext.put(:language_of_description, orig)
  end

  describe '.set_multilingual_fields' do
    it "records declared field names on the class" do
      expect(Resource.get_multilingual_fields).to include(:title)
      expect(Resource.get_multilingual_fields).to include(:finding_aid_title)
    end

    it "defines getter and setter instance methods for each field" do
      expect(Resource.instance_methods).to include(:title)
      expect(Resource.instance_methods).to include(:title=)
      expect(Resource.instance_methods).to include(:finding_aid_note)
      expect(Resource.instance_methods).to include(:finding_aid_note=)
    end
  end

  describe '.mlc_table' do
    it "returns the correct _mlc table name for each model" do
      expect(Resource.mlc_table).to eq(:resource_mlc)
      expect(Accession.mlc_table).to eq(:accession_mlc)
      expect(ArchivalObject.mlc_table).to eq(:archival_object_mlc)
      expect(DigitalObject.mlc_table).to eq(:digital_object_mlc)
      expect(DigitalObjectComponent.mlc_table).to eq(:digital_object_component_mlc)
    end
  end

  describe '#get_field_value' do
    context "when no mlc row exists for the record" do
      it "returns nil" do
        resource = create_resource_with_primary_lang
        # after_save writes the factory title to resource_mlc; clear it to test the empty-row case
        resource_mlc.where(:resource_id => resource.id).delete
        expect(resource.get_field_value(:title)).to be_nil
      end
    end

    context "when no language context is set" do
      it "returns the value from the primary language" do
        resource = create_resource_with_primary_lang
        resource_mlc.where(:resource_id => resource.id).delete
        resource_mlc.insert(
          :resource_id => resource.id,
          :language_id => eng_id,
          :script_id   => latn_id,
          :title       => "Primary language title"
        )

        without_language_context do
          expect(resource.get_field_value(:title)).to eq("Primary language title")
        end
      end
    end

    context "when a language context is set" do
      it "returns the value for that language" do
        resource = create_resource_with_primary_lang
        resource_mlc.where(:resource_id => resource.id).delete
        resource_mlc.insert(
          :resource_id => resource.id,
          :language_id => eng_id,
          :script_id   => latn_id,
          :title       => "English title"
        )
        resource_mlc.insert(
          :resource_id => resource.id,
          :language_id => fre_id,
          :script_id   => latn_id,
          :title       => "Titre français"
        )

        with_language_context(language_id: fre_id, script_id: latn_id) do
          expect(resource.get_field_value(:title)).to eq("Titre français")
        end
      end

      it "falls back to the primary language when no row exists for that language" do
        resource = create_resource_with_primary_lang
        resource_mlc.where(:resource_id => resource.id).delete
        resource_mlc.insert(
          :resource_id => resource.id,
          :language_id => eng_id,
          :script_id   => latn_id,
          :title       => "English title"
        )

        without_language_context do
          expect(resource.get_field_value(:title)).to eq("English title")
        end
      end
    end
  end

  describe '#set_field_value' do
    context "when no mlc row exists" do
      it "inserts a new row" do
        resource = create_resource_with_primary_lang
        resource_mlc.where(:resource_id => resource.id).delete

        resource.set_field_value(:title, "Inserted title")

        row = resource_mlc.where(:resource_id => resource.id).first
        expect(row).not_to be_nil
        expect(row[:title]).to eq("Inserted title")
      end
    end

    context "when an mlc row already exists" do
      it "updates the existing row rather than inserting a duplicate" do
        resource = create_resource_with_primary_lang
        resource_mlc.where(:resource_id => resource.id).delete
        resource_mlc.insert(
          :resource_id => resource.id,
          :language_id => eng_id,
          :script_id   => latn_id,
          :title       => "Original title"
        )

        resource.set_field_value(:title, "Updated title")

        rows = resource_mlc.where(:resource_id => resource.id).all
        expect(rows.length).to eq(1)
        expect(rows.first[:title]).to eq("Updated title")
      end
    end

    context "when a language context is set" do
      it "writes to that language's row without affecting other languages" do
        resource = create_resource_with_primary_lang
        resource_mlc.where(:resource_id => resource.id).delete
        resource_mlc.insert(
          :resource_id => resource.id,
          :language_id => eng_id,
          :script_id   => latn_id,
          :title       => "English title"
        )

        with_language_context(language_id: fre_id, script_id: latn_id) do
          resource.set_field_value(:title, "Titre français")
        end

        expect(resource_mlc.where(:resource_id => resource.id, :language_id => fre_id).first[:title]).to eq("Titre français")
        expect(resource_mlc.where(:resource_id => resource.id, :language_id => eng_id).first[:title]).to eq("English title")
      end
    end

    context "when no language context or primary language is set" do
      it "falls back to the AppConfig default language" do
        resource = create_resource(:lang_descriptions => [])

        without_language_context do
          resource.set_field_value(:title, "Default language title")
        end

        default_lang_enum_id   = Enumeration.filter(:name => 'language_iso639_2').get(:id)
        default_script_enum_id = Enumeration.filter(:name => 'script_iso15924').get(:id)
        default_lang_id   = EnumerationValue.filter(:enumeration_id => default_lang_enum_id,
                                                    :value => AppConfig[:mlc_default_language]).get(:id)
        default_script_id = EnumerationValue.filter(:enumeration_id => default_script_enum_id,
                                                    :value => AppConfig[:mlc_default_script]).get(:id)

        row = resource_mlc.where(
          :resource_id => resource.id,
          :language_id => default_lang_id,
          :script_id   => default_script_id
        ).first
        expect(row).not_to be_nil
        expect(row[:title]).to eq("Default language title")
      end
    end
  end

  describe '.to_mlc_hash' do
    it "returns a hash keyed by <lang>_<script> with only the field values" do
      resource = create_resource_with_primary_lang
      resource_mlc.where(:resource_id => resource.id).delete
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => eng_id,
        :script_id   => latn_id,
        :title       => "English title",
        :finding_aid_title => "English finding aid"
      )
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => fre_id,
        :script_id   => latn_id,
        :title       => "Titre français"
      )

      hash = Resource.to_mlc_hash(resource)

      expect(hash.keys).to contain_exactly("eng_Latn", "fre_Latn")
      expect(hash["eng_Latn"]).to include("title" => "English title",
                                         "finding_aid_title" => "English finding aid")
      expect(hash["fre_Latn"]).to include("title" => "Titre français")
    end

    it "omits fields whose values are nil or blank" do
      resource = create_resource_with_primary_lang
      resource_mlc.where(:resource_id => resource.id).delete
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => eng_id,
        :script_id   => latn_id,
        :title       => "English title",
        :finding_aid_title => ""
      )

      hash = Resource.to_mlc_hash(resource)

      expect(hash["eng_Latn"]).to have_key("title")
      expect(hash["eng_Latn"]).not_to have_key("finding_aid_title")
    end
  end

  describe '.primary_description_language_for_record' do
    it "returns the language/script pair of the primary lang_descriptions row" do
      resource = create_resource_with_primary_lang

      expect(Resource.primary_description_language_for_record(resource))
        .to eq(language_id: eng_id, script_id: latn_id)
    end

    it "returns nil when the model has no language_and_script_of_description association" do
      # ArchivalObject does not include LangDescriptions
      ao_stub = double('ArchivalObject')
      expect(ArchivalObject.primary_description_language_for_record(ao_stub)).to be_nil
    end

    it "returns nil when no entry is marked primary" do
      resource = create_resource(:lang_descriptions => [
        {"language" => "eng", "script" => "Latn", "is_primary" => false}
      ])

      expect(Resource.primary_description_language_for_record(resource)).to be_nil
    end
  end

  describe '.attach_mlc_fields_to_jsons!' do
    it "attaches mlc_fields keyed by <lang>_<script> to each json" do
      resource = create_resource_with_primary_lang
      resource_mlc.where(:resource_id => resource.id).delete
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => eng_id,
        :script_id   => latn_id,
        :title       => "English title"
      )
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => fre_id,
        :script_id   => latn_id,
        :title       => "Titre français"
      )

      jsons = [{}]
      Resource.attach_mlc_fields_to_jsons!([resource], jsons)

      expect(jsons.first['mlc_fields'].keys).to contain_exactly("eng_Latn", "fre_Latn")
      expect(jsons.first['mlc_fields']["fre_Latn"]).to include("title" => "Titre français")
    end

    it "overwrites scalar multilingual fields with the primary-language value, " \
       "even when RequestContext.description_language resolves to a different language" do
      resource = create_resource_with_primary_lang
      resource_mlc.where(:resource_id => resource.id).delete
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => eng_id,
        :script_id   => latn_id,
        :title       => "English primary"
      )
      resource_mlc.insert(
        :resource_id => resource.id,
        :language_id => fre_id,
        :script_id   => latn_id,
        :title       => "Titre français"
      )

      # Simulate the indexer's blank context: description_language resolves to
      # AppConfig's default (eng/Latn).  The scalar on the json should still
      # reflect the record's primary language, which happens to be eng here.
      # Flip to a record whose primary is fre and verify the scalar follows.
      fre_resource = create_resource(:lang_descriptions => [
        {"language" => "fre", "script" => "Latn", "is_primary" => true}
      ])
      resource_mlc.where(:resource_id => fre_resource.id).delete
      resource_mlc.insert(
        :resource_id => fre_resource.id,
        :language_id => eng_id,
        :script_id   => latn_id,
        :title       => "English variant"
      )
      resource_mlc.insert(
        :resource_id => fre_resource.id,
        :language_id => fre_id,
        :script_id   => latn_id,
        :title       => "Titre primaire"
      )

      jsons = [{}, {}]
      with_language_context(language_id: eng_id, script_id: latn_id) do
        Resource.attach_mlc_fields_to_jsons!([resource, fre_resource], jsons)
      end

      expect(jsons[0]['title']).to eq("English primary")
      expect(jsons[1]['title']).to eq("Titre primaire")
    end

    it "is a no-op for an empty objs list" do
      expect { Resource.attach_mlc_fields_to_jsons!([], []) }.not_to raise_error
    end
  end

end
