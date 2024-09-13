require 'spec_helper'

describe "FindingAidPDF" do
  it "generates html for pdf export with archival object component unique identifier" do
    now = Time.now.to_i
    archival_object_component_unique_identifier = SecureRandom.uuid

    repository = create(:repo, :repo_code => "finding_aid_pdf_#{now}", publish: true)
    set_repo repository

    resource = create(:resource, title: "Resource Title #{now}", publish: true, deaccessions: [build(:json_deaccession)])
    archival_object = create(:archival_object,
      title: "Archival Object Title #{now}",
      resource: { 'ref' => resource.uri },
      publish: true,
      component_id: archival_object_component_unique_identifier
    )

    run_indexers

    pdf = FindingAidPDF.new(repository.id, resource.id, ArchivesSpaceClient.instance, nil)
    source_file = pdf.source_file
    html = File.read(source_file)

    expect(html).to include "<dt>Identifier</dt>\n                    <dd>#{archival_object.component_id}</dd>"
  end
end
