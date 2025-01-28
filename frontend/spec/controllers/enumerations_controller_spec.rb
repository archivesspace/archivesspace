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
end
