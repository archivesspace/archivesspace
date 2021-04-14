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
end

describe GenericRecordController, type: :controller do
  it 'should implement :current_record for plugin controllers' do
    expect { rec = controller.send(:current_record) }.to raise_error(/method 'current_record' not implemented for controller/)
  end
end
