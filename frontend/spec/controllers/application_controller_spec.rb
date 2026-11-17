# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

class GenericRecordController < ApplicationController; end

describe ApplicationController, type: :controller do
  it 'allows incoming integers to be 0 or greater' do
    params = { "file_size_bytes" => "100" }
    clean_params = controller.send(:cleanup_params_for_schema, params , JSONModel(:file_version).schema)
    expect(clean_params["file_size_bytes"]).to eq 100

    params = { "file_size_bytes" => "0" }
    clean_params = controller.send(:cleanup_params_for_schema, params , JSONModel(:file_version).schema)
    expect(clean_params["file_size_bytes"]).to eq 0
  end

  describe '#refresh_preferences' do
    let(:now) { Time.now.to_i }

    around do |example|
      original = MemoryLeak::Resources.get(:preferences_system_mtime)
      example.run
    ensure
      MemoryLeak::Resources.set(:preferences_system_mtime, original)
    end

    before do
      session[:preferences] = { 'locale' => 'en' }
      session[:last_preference_refresh] = now
    end

    it 'drops preferences cached in the same second as a preference change' do
      MemoryLeak::Resources.set(:preferences_system_mtime, now)

      controller.send(:refresh_preferences)

      expect(session[:preferences]).to be_nil
    end

    it 'keeps preferences cached after the latest preference change' do
      MemoryLeak::Resources.set(:preferences_system_mtime, now - 1)

      controller.send(:refresh_preferences)

      expect(session[:preferences]).to eq('locale' => 'en')
    end
  end

  describe '#actions_column_position' do
    def position_for(stored)
      allow(controller).to receive(:browse_columns).and_return('accession_actions_column_position' => stored)
      controller.send(:actions_column_position, 'accession')
    end

    it 'returns a stored start or end position' do
      expect(position_for('start')).to eq 'start'
      expect(position_for('end')).to eq 'end'
    end

    it 'falls back to start when no valid position is stored' do
      expect(position_for(nil)).to eq 'start'
      expect(position_for('')).to eq 'start'
      expect(position_for('left')).to eq 'start'
    end
  end
end

describe GenericRecordController, type: :controller do
  it 'should implement :current_record for plugin controllers' do
    expect { rec = controller.send(:current_record) }.to raise_error(/method 'current_record' not implemented for controller/)
  end
end
