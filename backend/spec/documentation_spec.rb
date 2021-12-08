require 'spec_helper'

describe "Factory coverage supporting API documentation examples" do

  it "alerts you when a factory_bot_helper example is missing for a JSONModel" do
    # The API docs rely on examples being provided for all JSONModels in
    # `common/spec/lib/factory_bot_helpers.rb`.  This test will fail if that is
    # not the case.
    missing = []
    JSONModel.models.each_pair do |type, _|
      next if type =~ /^abstract_/
      begin
        build("json_#{type}".to_sym)
      rescue => err
        missing << err.message if err.message.include?("Factory not registered")
      end
    end

    missing = missing.uniq
    expect(missing).to eq([])
  end
end
