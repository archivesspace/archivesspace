RSpec.shared_examples "a record with display file versions" do |model, factory|
  def display_flag_file_version(opts = {})
    build(:json_file_version, {
            :publish => true,
            :file_uri => "http://foo.com/#{generate(:alphanumstr)}",
            :use_statement => 'image-service'
          }.merge(opts))
  end

  def create_with_file_versions(model, factory, file_versions)
    record = model.create_from_json(build(factory, :publish => true, :file_versions => file_versions))
    model.to_jsonmodel(record.id)['file_versions']
  end

  [:is_display_thumbnail, :is_display_link].each do |flag|
    it "won't allow more than one file_version flagged '#{flag}'" do
      expect {
        create_with_file_versions(model, factory, [display_flag_file_version(flag => true),
                                                   display_flag_file_version(flag => true)])
      }.to raise_error(Sequel::ValidationFailed)
    end

    it "doesn't allow an unpublished file_version flagged '#{flag}'" do
      expect {
        create_with_file_versions(model, factory, [display_flag_file_version(:publish => false, flag => true),
                                                   display_flag_file_version])
      }.to raise_error(Sequel::ValidationFailed)
    end
  end

  it "allows a display thumbnail and a display link on different file_versions" do
    file_versions = create_with_file_versions(model, factory, [display_flag_file_version(:is_display_thumbnail => true),
                                                               display_flag_file_version(:is_display_link => true)])

    expect(file_versions.map { |fv| [fv['is_display_thumbnail'], fv['is_display_link']] }).to eq([[true, false], [false, true]])
  end

  it "allows one file_version to be both the display thumbnail and the display link" do
    file_versions = create_with_file_versions(model, factory, [display_flag_file_version(:is_display_thumbnail => true,
                                                                                         :is_display_link => true)])

    expect(file_versions.map { |fv| [fv['is_display_thumbnail'], fv['is_display_link']] }).to eq([[true, true]])
  end
end
