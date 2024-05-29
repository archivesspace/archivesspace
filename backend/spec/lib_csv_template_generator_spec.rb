require_relative "spec_helper.rb"

describe 'CsvTemplateGenerator::Template' do
  TEMPLATES_DIR = File.join(ASUtils.find_base_directory, 'templates')

  let(:now) { Time.now.to_i }
  let(:resource) { create(:json_resource) }
  let!(:archival_objects) { create_list(:json_archival_object, 20, :resource => { :ref => resource.uri }) }

  subject { CsvTemplateGenerator }

  it 'successfully generates a CSV with resource and archival object URIs prefilled' do
    # Load Digital Object CSV template file to get columns
    csv_template_path = File.join(TEMPLATES_DIR, 'bulk_import_DO_template.csv')
    csv_data = CSV.read(csv_template_path)
    expect(csv_data.count).to eq 2
    columns = csv_data[0] # CSV headers
    column_explanations = csv_data[1] # CSV header explanations

    result_enumerator = subject.csv_for_digital_object_generation(resource.id)

    expect(result_enumerator.entries.length).to eq 23

    # Match CSV headers.
    expect(result_enumerator.entries[1]).to eq columns.join(',') + "\n"

    # Match column explanations.
    # May contain commas in their values, which causes them to be escaped in the generated CSV.
    parse_explanations_from_generated_csv = CSV.parse(result_enumerator.entries[2])
    expect(parse_explanations_from_generated_csv.length).to eq 1
    expect(parse_explanations_from_generated_csv[0].join(',')).to eq column_explanations.join(',')

    for x in 0..(archival_objects.length - 1)
      expect(result_enumerator.entries[x + 3]).to include resource.uri
      expect(result_enumerator.entries[x + 3]).to include archival_objects[x].uri
    end
  end
end
