require 'spec_helper'
require 'rails_helper'

describe EnumerationsController, type: :controller do
  render_views

  let(:enum_id) { JSONModel(:enumeration).all.select {|enum| enum.name == "language_iso639_2" }.first.id }

  it "translates the label for an enumeration value" do
    apply_session_to_controller(controller, 'admin', 'admin')
    get :index, params: { id: enum_id }
    result = Capybara.string(response.body)
    first_row = result.first(".enumeration-list").first("tbody").first("tr")
    key_cell = first_row.find("td[1]")
    value_cell = first_row.find("td[2]")
    expect(key_cell.text).to eq "aar"
    expect(value_cell.text).to eq "Afar"
  end

  describe 'set_default' do
    before(:all) do
      @enumeration = JSONModel(:enumeration).all.find { |enum| enum.name == 'extent_extent_type' }
      @original_default = @enumeration.default_value
      @value = "set_default_spec_#{Time.now.to_i}"
      @enumeration.values += [@value]
      @enumeration.save
      @enumeration_value = JSONModel(:enumeration).find(@enumeration.id).enumeration_values.find { |v| v['value'] == @value }
    end

    after(:all) do
      JSONModel(:enumeration_value).find(@enumeration_value['id']).set_suppressed(false)
      enumeration = JSONModel(:enumeration).find(@enumeration.id)
      enumeration.default_value = @original_default
      enumeration.save
      enumeration = JSONModel(:enumeration).find(@enumeration.id)
      enumeration.values -= [@value]
      enumeration.save
    end

    before(:each) do
      apply_session_to_controller(controller, 'admin', 'admin')
    end

    it 'reports the default as set' do
      JSONModel(:enumeration_value).find(@enumeration_value['id']).set_suppressed(false)

      post :set_default, params: { id: @enumeration.id, value: @value }

      expect(flash[:success]).to eq 'Default Value Set'
      expect(JSONModel(:enumeration).find(@enumeration.id).default_value).to eq @value
    end

    it 'reports an error when the value is suppressed' do
      JSONModel(:enumeration_value).find(@enumeration_value['id']).set_suppressed(true)

      post :set_default, params: { id: @enumeration.id, value: @value }

      expect(flash[:error]).to eq 'Failed to set Default Value'
      expect(JSONModel(:enumeration).find(@enumeration.id).default_value).not_to eq @value
    end
  end
end
