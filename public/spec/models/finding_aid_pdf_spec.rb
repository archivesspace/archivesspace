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

  context "repository logo" do
    let(:logo_url) { 'https://images.example.org/logo.png' }
    let(:now) { Time.now.to_i }
    let(:logo) do
      file = Tempfile.new(['pdf_image', '.png'])
      file.close
      file
    end

    def build_pdf(image_url: logo_url)
      repository = create(:repo,
                          repo_code: "finding_aid_pdf_logo_#{now}_#{SecureRandom.hex(3)}",
                          publish: true,
                          url: 'https://archives.example.edu/',
                          image_url: image_url)
      set_repo repository
      resource = create(:resource, title: "Resource Title #{now}", publish: true)
      run_indexers

      [repository, FindingAidPDF.new(repository.id, resource.id, ArchivesSpaceClient.instance, nil)]
    end

    after { logo.unlink }

    it "puts a local copy of the logo on the title page" do
      path = logo.path
      expect(ASHTTP).to receive(:download_image)
        .with(logo_url, contact_url: 'https://archives.example.edu/')
        .and_return(logo)

      _repository, pdf = build_pdf
      html = File.read(pdf.source_file)

      expect(html).to include "file://#{path}"
      expect(html).not_to include logo_url
    end

    it "falls back to the original logo URL when the download fails" do
      allow(ASHTTP).to receive(:download_image).and_return(nil)

      _repository, pdf = build_pdf
      html = File.read(pdf.source_file)

      expect(html).to include logo_url
    end

    it "uses the default logo and downloads nothing when the repository has no logo" do
      expect(ASHTTP).not_to receive(:download_image)

      _repository, pdf = build_pdf(image_url: nil)
      html = File.read(pdf.source_file)

      expect(html).to include 'ArchivesSpaceLogo_for_pdf'
    end

    it "removes the downloaded logo once the PDF is generated" do
      path = logo.path
      allow(ASHTTP).to receive(:download_image).and_return(logo)

      _repository, pdf = build_pdf
      pdf_file = pdf.generate

      expect(File.exist?(path)).to be false
    ensure
      pdf_file&.unlink
    end
  end
end
