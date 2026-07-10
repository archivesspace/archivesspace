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

end
