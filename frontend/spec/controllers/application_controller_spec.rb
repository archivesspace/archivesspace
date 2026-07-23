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

  describe '#set_description_language' do
    controller do
      skip_before_action :unauthorised_access

      def index
        head :ok
      end
    end

    before(:each) do
      apply_session_to_controller(controller, 'admin', 'admin')
    end

    after(:each) do
      JSONModel::HTTP.current_description_language = nil
    end

    context 'when language_of_description param is present and valid' do
      it 'sets current_description_language to the supplied value' do
        get :index, params: { language_of_description: 'eng_Latn' }
        expect(Thread.current[:description_language]).to eq('eng_Latn')
      end

      it 'accepts any valid three-letter language code with four-letter script code' do
        get :index, params: { language_of_description: 'fre_Latn' }
        expect(Thread.current[:description_language]).to eq('fre_Latn')
      end
    end

    context 'when language_of_description param is absent' do
      it 'sets current_description_language to nil' do
        get :index
        expect(Thread.current[:description_language]).to be_nil
      end

      it 'clears a language that was set on a previous request' do
        JSONModel::HTTP.current_description_language = 'fre_Latn'
        get :index
        expect(Thread.current[:description_language]).to be_nil
      end
    end

    context 'when language_of_description param has an invalid format' do
      it 'sets current_description_language to nil' do
        ['../../etc/passwd', 'english_Latin', ''].each do |invalid|
          get :index, params: { language_of_description: invalid }
          expect(Thread.current[:description_language]).to be_nil
        end
      end
    end
  end
end

describe GenericRecordController, type: :controller do
  it 'should implement :current_record for plugin controllers' do
    expect { rec = controller.send(:current_record) }.to raise_error(/method 'current_record' not implemented for controller/)
  end
end
