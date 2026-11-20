require 'spec_helper'

def print_to_pdf_job( resource_uri )
  build( :json_job,
         :job => build(:json_print_to_pdf_job, :source => resource_uri)
       )
end

describe "Print to PDF job model" do

  # Avoid PDF rendering
  class StubASFop
    @last_xml = nil

    def self.last_xml
      @last_xml
    end

    def self.last_xml=(value)
      @last_xml = value
    end

    def self.last_args
      @last_args
    end

    def self.last_args=(value)
      @last_args = value
    end

    def self.reset
      @last_xml = nil
      @last_args = nil
    end

    def initialize(source, *args)
      self.class.last_xml = source
      self.class.last_args = args
      @tmp = ASUtils.tempfile('tmp.pdf')
      @tmp.write("PDF")
      @tmp.rewind
    end

    def to_pdf
      @tmp
    end
  end

  let(:user) { create_nobody_user }

  it "is registered as an available job type" do
    expect(JobRunner.registered_job_types).to have_key('print_to_pdf_job')
  end

  it "can create a print to pdf job" do
    opts = {:title => generate(:generic_title)}
    resource = create_resource(opts)

    json = print_to_pdf_job(resource.uri)
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user )

    expect(job).not_to be_nil
    expect(job.job_type).to eq("print_to_pdf_job")
    expect(job.owner.username).to eq('nobody')
  end

  it "can create a pdf from a published resource" do
    opts = {:title => generate(:generic_title), :publish => true}
    resource = create_resource(opts)

    json = print_to_pdf_job(resource.uri)
    job = Job.create_from_json( json,
                               :repo_id => $repo_id,
                               :user => user )
    jr = JobRunner.for(job)
    jr.run

    job.refresh
    expect(job.job_files.length).to eq(1)
  end

  it "will create a pdf from an unpublished resource" do
    opts = {:title => generate(:generic_title), :publish => false}
    resource = create_resource(opts)

    json = print_to_pdf_job(resource.uri)
    job = Job.create_from_json( json,
                                :repo_id => $repo_id,
                                :user => user )
    jr = JobRunner.for(job)
    jr.run

    job.refresh
    expect(job.job_files.length).to eq(1)
  end

  context "repository logo" do
    let(:resource) { create_resource(title: generate(:generic_title), publish: true) }
    let(:repo) { Repository[$repo_id] }
    let!(:logo) do
      file = Tempfile.new(['pdf_image', '.png'])
      file.close
      file
    end
    # Tempfile#unlink clears #path, so remember where the file was
    let!(:logo_path) { logo.path }

    before do
      repo.update(image_url: 'https://images.example.org/logo.png')
      stub_const('ASFop', StubASFop)
    end

    after do
      StubASFop.reset
      logo.unlink
    end

    def run_job
      json = print_to_pdf_job(resource.uri)
      job = Job.create_from_json(json, repo_id: $repo_id, user: user)
      JobRunner.for(job).run
    end

    it "uses a downloaded copy of the logo and deletes it afterwards" do
      expect(ASHTTP).to receive(:download_image)
        .with('https://images.example.org/logo.png', contact_url: repo.url)
        .and_return(logo)

      run_job

      expect(StubASFop.last_args.last).to eq("file://#{logo_path}")
      expect(File.exist?(logo_path)).to be false
    end

    it "falls back to the original logo URL when the download fails" do
      allow(ASHTTP).to receive(:download_image).and_return(nil)

      run_job

      expect(StubASFop.last_args.last).to eq('https://images.example.org/logo.png')
    end

    it "removes the downloaded logo even when the PDF fails to render" do
      allow(ASHTTP).to receive(:download_image).and_return(logo)
      allow(StubASFop).to receive(:new).and_raise('render failed')

      expect { run_job }.to raise_error(RuntimeError, 'render failed')

      expect(File.exist?(logo_path)).to be false
    end

    it "does not download anything when the repository has no logo" do
      repo.update(image_url: nil)
      expect(ASHTTP).not_to receive(:download_image)

      run_job

      expect(StubASFop.last_args.last).to be_nil
    end
  end

  context "include_uris option" do
    let(:resource) { create_resource(title: generate(:generic_title), publish: true) }
    let(:aspace_uri_xpath) { "//did/unitid[@type='aspace_uri']" }

    before do
      allow(Search).to receive(:records_for_uris).and_return({ 'results' => [] })
      stub_const('ASFop', StubASFop)
    end

    after do
      StubASFop.reset
    end

    def run_job_with_uris_option(resource_uri, include_uris)
      json = build(:json_job,
                   job: build(:json_print_to_pdf_job,
                             source: resource_uri,
                             include_uris: include_uris))
      job = Job.create_from_json(json, repo_id: $repo_id, user: user)

      JobRunner.for(job).run

      doc = Nokogiri::XML(StubASFop.last_xml)
      doc.remove_namespaces!
      doc
    end

    it "includes <unitid type='aspace_uri'> when include_uris is true" do
      doc = run_job_with_uris_option(resource.uri, true)
      uri_element = doc.at_xpath(aspace_uri_xpath)

      expect(uri_element.text).to eq(resource.uri)
    end

    it "excludes <unitid type='aspace_uri'> when include_uris is false" do
      doc = run_job_with_uris_option(resource.uri, false)

      expect(doc.at_xpath(aspace_uri_xpath)).to be_nil
    end
  end
end
