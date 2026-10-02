require 'spec_helper'

describe 'MLC display string fallbacks in tree queries' do
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

  def default_lang_id
    enum_id = Enumeration.filter(:name => 'language_iso639_2').get(:id)
    EnumerationValue.filter(:enumeration_id => enum_id, :value => AppConfig[:mlc_default_language]).get(:id)
  end

  def default_script_id
    enum_id = Enumeration.filter(:name => 'script_iso15924').get(:id)
    EnumerationValue.filter(:enumeration_id => enum_id, :value => AppConfig[:mlc_default_script]).get(:id)
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

  let!(:resource) do
    create_resource(
      :lang_descriptions => [{
        "language"   => "eng",
        "script"     => "Latn",
        "is_primary" => true
      }]
    )
  end

  let!(:ao_with_eng) do
    ao = create_archival_object(:resource => {:ref => resource.uri}, :title => "AO with eng")
    ArchivalObject.db[:archival_object_mlc].where(:archival_object_id => ao.id).delete
    ArchivalObject.db[:archival_object_mlc].insert(
      :archival_object_id => ao.id,
      :language_id        => eng_id,
      :script_id          => latn_id,
      :display_string     => "English AO title"
    )
    ao
  end

  let!(:ao_with_fre) do
    ao = create_archival_object(:resource => {:ref => resource.uri}, :title => "AO with fre")
    ArchivalObject.db[:archival_object_mlc].where(:archival_object_id => ao.id).delete
    ArchivalObject.db[:archival_object_mlc].insert(
      :archival_object_id => ao.id,
      :language_id        => fre_id,
      :script_id          => latn_id,
      :display_string     => "French AO title"
    )
    ao
  end

  let!(:ao_with_both) do
    ao = create_archival_object(:resource => {:ref => resource.uri}, :title => "AO with both")
    ArchivalObject.db[:archival_object_mlc].where(:archival_object_id => ao.id).delete
    ArchivalObject.db[:archival_object_mlc].insert(
      :archival_object_id => ao.id,
      :language_id        => eng_id,
      :script_id          => latn_id,
      :display_string     => "Both: English title"
    )
    ArchivalObject.db[:archival_object_mlc].insert(
      :archival_object_id => ao.id,
      :language_id        => fre_id,
      :script_id          => latn_id,
      :display_string     => "Both: French title"
    )
    ao
  end

  let!(:ao_no_mlc) do
    ao = create_archival_object(:resource => {:ref => resource.uri}, :title => "AO with no MLC")
    ArchivalObject.db[:archival_object_mlc].where(:archival_object_id => ao.id).delete
    ao
  end

  shared_examples 'a multilingual display string' do
    context 'when the requested language row exists' do
      it 'returns the title for the requested language' do
        with_language_context(language_id: fre_id, script_id: latn_id) do
          results = subject.call([ao_with_fre.id])
          expect(results[ao_with_fre.id]).to eq("French AO title")
        end
      end

      it "returns each node's title in the requested language when multiple rows match" do
        with_language_context(language_id: fre_id, script_id: latn_id) do
          results = subject.call([ao_with_fre.id, ao_with_both.id])
          expect(results[ao_with_fre.id]).to eq("French AO title")
          expect(results[ao_with_both.id]).to eq("Both: French title")
        end
      end
    end

    context 'when no row exists for the requested language' do
      context "and a row exists for the parent record's primary language" do
        it 'falls back to the primary language title' do
          with_language_context(language_id: fre_id, script_id: latn_id) do
            results = subject.call([ao_with_eng.id])
            expect(results[ao_with_eng.id]).to eq("English AO title")
          end
        end
      end

      context 'and no primary language row exists but an AppConfig default row does' do
        it 'falls back to the AppConfig default language title' do
          ArchivalObject.db[:archival_object_mlc].insert(
            :archival_object_id => ao_no_mlc.id,
            :language_id        => default_lang_id,
            :script_id          => default_script_id,
            :display_string     => "AppConfig default AO title"
          )

          with_language_context(language_id: fre_id, script_id: latn_id) do
            results = subject.call([ao_no_mlc.id])
            expect(results[ao_no_mlc.id]).to eq("AppConfig default AO title")
          end
        end
      end

      context 'and no MLC rows exist at all' do
        it 'returns nil for that node rather than raising' do
          with_language_context(language_id: fre_id, script_id: latn_id) do
            results = subject.call([ao_no_mlc.id])
            expect(results[ao_no_mlc.id]).to be_nil
          end
        end
      end
    end

    context 'when no language context is set' do
      it 'returns the primary language title' do
        without_language_context do
          results = subject.call([ao_with_eng.id])
          expect(results[ao_with_eng.id]).to eq("English AO title")
        end
      end
    end

    context 'with a mixed set of nodes' do
      it 'returns the best available title for each node independently' do
        with_language_context(language_id: fre_id, script_id: latn_id) do
          results = subject.call([ao_with_fre.id, ao_with_eng.id, ao_no_mlc.id])

          expect(results[ao_with_fre.id]).to eq("French AO title")
          expect(results[ao_with_eng.id]).to eq("English AO title")
          expect(results[ao_no_mlc.id]).to be_nil
        end
      end
    end
  end

  describe 'Trees#node_display_strings called on the resource model directly' do
    subject do
      lambda { |node_ids| resource.send(:node_display_strings, node_ids) }
    end

    it_behaves_like 'a multilingual display string'
  end

  describe 'LargeTree#mlc_display_strings called via the large tree waypoint' do
    subject do
      lambda do |node_ids|
        large_tree = LargeTree.new(resource, { :published_only => false })
        large_tree.send(:mlc_display_strings, Resource.db, node_ids)
      end
    end

    it_behaves_like 'a multilingual display string'
  end

  describe 'LargeTreeDigitalObject#waypoint label fallback for digital object components' do
    let!(:digital_object) do
      create_digital_object(
        :lang_descriptions => [{
          "language"   => "eng",
          "script"     => "Latn",
          "is_primary" => true
        }]
      )
    end

    let!(:doc_with_eng) do
      doc = create_digital_object_component(
        :digital_object => {:ref => digital_object.uri},
        :title => "DOC with eng label"
      )
      DigitalObjectComponent.db[:digital_object_component_mlc].where(:digital_object_component_id => doc.id).delete
      DigitalObjectComponent.db[:digital_object_component_mlc].insert(
        :digital_object_component_id => doc.id,
        :language_id                 => eng_id,
        :script_id                   => latn_id,
        :label                       => "English label"
      )
      doc
    end

    let!(:doc_with_fre) do
      doc = create_digital_object_component(
        :digital_object => {:ref => digital_object.uri},
        :title => "DOC with fre label"
      )
      DigitalObjectComponent.db[:digital_object_component_mlc].where(:digital_object_component_id => doc.id).delete
      DigitalObjectComponent.db[:digital_object_component_mlc].insert(
        :digital_object_component_id => doc.id,
        :language_id                 => fre_id,
        :script_id                   => latn_id,
        :label                       => "French label"
      )
      doc
    end

    let!(:doc_no_mlc) do
      doc = create_digital_object_component(
        :digital_object => {:ref => digital_object.uri},
        :title => "DOC with no label"
      )
      DigitalObjectComponent.db[:digital_object_component_mlc].where(:digital_object_component_id => doc.id).delete
      doc
    end

    def invoke_waypoint(doc_ids)
      decorator = LargeTreeDigitalObject.new(digital_object)
      response = doc_ids.map { |id| {} }
      decorator.waypoint(response, doc_ids)
      doc_ids.each_with_object({}).with_index do |(id, h), idx|
        h[id] = response[idx]['label']
      end
    end

    context 'when the requested language label row exists' do
      it 'sets the label from the requested language' do
        with_language_context(language_id: fre_id, script_id: latn_id) do
          labels = invoke_waypoint([doc_with_fre.id])
          expect(labels[doc_with_fre.id]).to eq("French label")
        end
      end
    end

    context 'when no row exists for the requested language' do
      context 'and the root digital object has a primary language row' do
        it 'falls back to the primary language label' do
          with_language_context(language_id: fre_id, script_id: latn_id) do
            labels = invoke_waypoint([doc_with_eng.id])
            expect(labels[doc_with_eng.id]).to eq("English label")
          end
        end
      end

      context 'and no primary language row exists but an AppConfig default label row does' do
        it 'falls back to the AppConfig default language label' do
          DigitalObjectComponent.db[:digital_object_component_mlc].insert(
            :digital_object_component_id => doc_no_mlc.id,
            :language_id                 => default_lang_id,
            :script_id                   => default_script_id,
            :label                       => "AppConfig default label"
          )

          with_language_context(language_id: fre_id, script_id: latn_id) do
            labels = invoke_waypoint([doc_no_mlc.id])
            expect(labels[doc_no_mlc.id]).to eq("AppConfig default label")
          end
        end
      end

      context 'and no rows exist for any language in the fallback chain' do
        it 'sets no label' do
          with_language_context(language_id: fre_id, script_id: latn_id) do
            labels = invoke_waypoint([doc_no_mlc.id])
            expect(labels[doc_no_mlc.id]).to be_nil
          end
        end
      end
    end

    context 'when no language context is set' do
      it 'sets the label from the primary language row' do
        without_language_context do
          labels = invoke_waypoint([doc_with_eng.id])
          expect(labels[doc_with_eng.id]).to eq("English label")
        end
      end
    end

    context 'with a mixed set of DOCs' do
      it "resolves each DOC's label independently" do
        with_language_context(language_id: fre_id, script_id: latn_id) do
          labels = invoke_waypoint([doc_with_fre.id, doc_with_eng.id, doc_no_mlc.id])
          expect(labels[doc_with_fre.id]).to eq("French label")
          expect(labels[doc_with_eng.id]).to eq("English label")
          expect(labels[doc_no_mlc.id]).to be_nil
        end
      end
    end
  end
end
