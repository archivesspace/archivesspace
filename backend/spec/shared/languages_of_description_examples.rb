# frozen_string_literal: true

shared_examples "a record with valid languages of description subrecords" do |factory_name, model_class|
  it "allows a single language of description to be flagged 'is_primary'" do
    json = build(factory_name, {
      :lang_descriptions => [
        build(:json_language_and_script_of_description, { :is_primary => true }),
        build(:json_language_and_script_of_description, { :is_primary => false }),
      ]
    })

    expect {
      model_class.create_from_json(json)
    }.not_to raise_error
  end

  it "won't allow more than one language of description to be flagged 'is_primary'" do
    json = build(factory_name, {
      :lang_descriptions => [
        build(:json_language_and_script_of_description, { :is_primary => true }),
        build(:json_language_and_script_of_description, { :is_primary => true }),
      ]
    })

    expect {
      model_class.create_from_json(json)
    }.to raise_error(Sequel::ValidationFailed)
  end
end
