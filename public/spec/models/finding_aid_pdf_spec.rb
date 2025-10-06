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

  it "sucessfully processes mixed content for titles" do
    now = Time.now.to_i

    repository = create(:repo, :repo_code => "finding_aid_pdf_#{now}", publish: true)
    set_repo repository

    resource = create(:resource, title: "Resource <b>Title</b> title&title; #{now}", publish: true, deaccessions: [build(:json_deaccession)])

    archival_object_with_html = create(:archival_object,
      title: "Archival <i>Object</i> <b>Title</b> #{now}",
      resource: { 'ref' => resource.uri },
      publish: true,
      component_id: SecureRandom.uuid
    )

    archival_object_with_ampersand = create(:archival_object,
      title: "Archival Object Title #{now} title & title",
      resource: { 'ref' => resource.uri },
      publish: true,
      component_id: SecureRandom.uuid
    )

    archival_object_with_ampersand_with_semicolon = create(:archival_object,
      title: "Archival Object Title &; #{now} &title;",
      resource: { 'ref' => resource.uri },
      publish: true,
      component_id: SecureRandom.uuid
    )

    archival_object_with_ampersand_and_html = create(:archival_object,
      title: "Archival Object <b>Title</b> #{now} title&title",
      resource: { 'ref' => resource.uri },
      publish: true,
      component_id: SecureRandom.uuid
    )

    archival_object_with_ampersand_with_semicolon_and_html = create(:archival_object,
      title: "Archival Object <b>Title</b> &; &&; &&&; #{now} &title;",
      resource: { 'ref' => resource.uri },
      publish: true,
      component_id: SecureRandom.uuid
    )

    run_indexers

    pdf = FindingAidPDF.new(repository.id, resource.id, ArchivesSpaceClient.instance, nil)
    source_file = pdf.source_file
    html = File.read(source_file)

    expect(html).to include "Archival <i>Object</i> <b>Title</b> #{now}"
    expect(html).to include "Archival Object Title #{now} title &amp; title"
    expect(html).to include "Archival Object Title &amp;; #{now} &amp;title;"
    expect(html).to include "Archival Object <b>Title</b> #{now} title&amp;title"
    expect(html).to include "Archival Object <b>Title</b> &amp;; &amp;&amp;; &amp;&amp;&amp;; #{now} &amp;title;"
  end

  it "generates html for pdf export with container indicators containing semicolons" do
    now = Time.now.to_i

    repository = create(:repo, :repo_code => "finding_aid_pdf_#{now}", publish: true)
    set_repo repository

    resource = create(:resource, title: "Resource Title #{now}", publish: true)

    top_container = create(:json_top_container,
      indicator: "Series 1: accession 2",
      type: "box")

    archival_object = create(:archival_object,
      title: "Archival Object with Semicolon Container #{now}",
      resource: { 'ref' => resource.uri },
      publish: true,
      instances: [build(:json_instance, {
        instance_type: 'text',
        sub_container: build(:json_sub_container, {
          top_container: { ref: top_container.uri },
          type_2: 'folder',
          indicator_2: '1'
        })
      })]
    )

    run_indexers

    pdf = FindingAidPDF.new(repository.id, resource.id, ArchivesSpaceClient.instance, nil)
    source_file = pdf.source_file
    html = File.read(source_file)

    expect(html).to include "box series 1: accession 2"
  end
end
