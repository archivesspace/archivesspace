RSpec.shared_context "digital object importer harness" do
  def family_headers_at(columns, namespace, index)
    index_1 = columns.select { |column| column.to_s.start_with?("#{namespace}_1_") }
    return index_1 if index.to_s == "1"

    index_1.map { |column| column.sub(/\A#{Regexp.escape(namespace)}_1_/, "#{namespace}_#{index}_") }
  end

  def import_digital_object_csv(columns, column_explanations, row, validate_only: false)
    csv_string = CSV.generate(col_sep: ',') do |csv|
      csv << columns
      csv << column_explanations
      csv << row.values
    end
    csv_filename = "bulk_import_DO_template_#{@now}_#{SecureRandom.uuid}.csv"
    csv_path = File.join(Dir.tmpdir, csv_filename)
    File.write(csv_path, csv_string)
    opts = { :repo_id => @resource[:repo_id], :rid => @resource[:id], :type => "resource",
             :filename => csv_filename, :filepath => csv_path, :load_type => "digital_object",
             :validate => validate_only }

    ImportDigitalObjects.new(opts[:filepath], "csv", @current_user, opts).run
  end

  before(:each) do
    @now = Time.now.to_i

    @current_user = User.find(:username => "admin")

    resource = JSONModel(:resource).from_hash("id" => 12,
                                              "title" => "Resource Title #{@now}",
                                              "dates" => [{
                                                "date_type" => "single",
                                                "label" => "creation",
                                                "expression" => "1901",
                                              }],
                                              "id_0" => "abc123",
                                              "level" => "collection",
                                              "lang_materials" => [{
                                                "language_and_script" => {
                                                  "language" => "eng",
                                                  "script" => "Latn",
                                                },
                                              }],
                                              "finding_aid_language" => "eng",
                                              "finding_aid_script" => "Latn",
                                              "ead_id" => "VFIRST01",
                                              "extents" => [{
                                                "portion" => "whole",
                                                "number" => "5 or so",
                                                "extent_type" => "reels",
                                              }])

    id = resource.save
    @resource = Resource.get_or_die(id)
    @archival_object = create(
      :json_archival_object,
      title: "Archival Object Title #{@now}",
      :resource => { :ref => @resource.uri }
    )
  end
end
