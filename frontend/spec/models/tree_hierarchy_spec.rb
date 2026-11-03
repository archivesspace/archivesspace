# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe InfiniteTreeHierarchy do
  describe '.child_type_for' do
    it 'returns the child type for each known root' do
      aggregate_failures do
        expect(described_class.child_type_for('resource')).to eq('archival_object')
        expect(described_class.child_type_for('digital_object')).to eq('digital_object_component')
        expect(described_class.child_type_for('classification')).to eq('classification_term')
      end
    end

    it 'accepts symbol root types' do
      aggregate_failures do
        expect(described_class.child_type_for(:resource)).to eq('archival_object')
        expect(described_class.child_type_for(:digital_object)).to eq('digital_object_component')
        expect(described_class.child_type_for(:classification)).to eq('classification_term')
      end
    end

    it 'returns nil for unknown or blank roots' do
      aggregate_failures do
        expect(described_class.child_type_for('accession')).to be_nil
        expect(described_class.child_type_for(nil)).to be_nil
      end
    end
  end

  describe '.as_json' do
    it 'exposes childType per root for browser injection' do
      expect(described_class.as_json).to eq(
        'resource' => { 'childType' => 'archival_object' },
        'digital_object' => { 'childType' => 'digital_object_component' },
        'classification' => { 'childType' => 'classification_term' }
      )
    end
  end
end
