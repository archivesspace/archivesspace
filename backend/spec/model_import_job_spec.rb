require 'spec_helper'
require 'stringio'
require 'csv'



describe 'Import job model' do


  before(:all) do
    converter = Class.new(Converter) do
      def self.instance_for(type, input_file)
        self.new(input_file) if type == 'nonce'
      end

      def run
        obj = ASpaceImport::JSONModel(:accession).new
        obj.title = IO.read(@input_file)
        obj.id_0 = '1234'
        obj.accession_date = '2010-10-10'
        @batch << obj
        @batch.flush
      end
    end

    Converter.register_converter(converter)
  end



  let(:job) do
    tmp = ASUtils.tempfile("doc-#{Time.now.to_i}")
    tmp.write("foobar")
    tmp.rewind

    $icky_hack_to_avoid_gc ||= []
    $icky_hack_to_avoid_gc << tmp

    json = build(:json_job,
                 :job_type => 'import_job',
                 :job => build(:json_import_job,
                               :filenames => [tmp.path],
                               :import_type => 'nonce'))


    user = create_nobody_user
    job = Job.create_from_json(json,
                               :repo_id => $repo_id,
                               :user => user)

    job.add_file(tmp)

    job
  end

  it "can create an import job" do
    expect(job).not_to be_nil
  end


  it "can be run and record the results" do
    job_runner = JobRunner.for(job)
    job_runner.run

    expect(job.created_records.count).to eq(1)
    expect(job.created_records.first[:record_uri]).to match(/accessions\/\d+$/)
    expect(Accession[JSONModel(:accession).id_for(job.created_records.first[:record_uri])].title).to eq('foobar')
  end


  it "reports a missing reference without exposing a Ruby trace" do
    tmp = ASUtils.tempfile("missing-subject-#{Time.now.to_i}")
    tmp.write(CSV.generate do |csv|
      csv << %w[accession_title accession_id_1 subject_1_record_id]
      csv << ['Missing Subject', generate(:alphanumstr), '999999999']
    end)
    tmp.rewind

    $icky_hack_to_avoid_gc ||= []
    $icky_hack_to_avoid_gc << tmp

    json = build(:json_job,
                 :job_type => 'import_job',
                 :job => build(:json_import_job,
                               :filenames => [tmp.path],
                               :import_type => 'accession_csv'))
    missing_reference_job = Job.create_from_json(json,
                                                 :repo_id => $repo_id,
                                                 :user => create_nobody_user)
    missing_reference_job.add_file(tmp)

    expect do
      JobRunner.for(missing_reference_job).run
    end.to raise_error(ReferenceError, /Reference does not exist/)

    output_stream, = missing_reference_job.get_output_stream
    output = output_stream.read
    expect(output).to include("Reference does not exist! (Reference: '/subjects/999999999')")
    expect(output).not_to include('Trace:')
    expect(output).not_to include('#<ReferenceError:')
  end


  it "reports unrecognized CSV headers without exposing a Ruby trace" do
    tmp = ASUtils.tempfile("obsolete-header-#{Time.now.to_i}")
    tmp.write(CSV.generate do |csv|
      csv << %w[accession_title accession_id_1 accession_number_1]
      csv << ['Obsolete header', generate(:alphanumstr), 'UD5V1']
    end)
    tmp.rewind

    $icky_hack_to_avoid_gc ||= []
    $icky_hack_to_avoid_gc << tmp

    json = build(:json_job,
                 :job_type => 'import_job',
                 :job => build(:json_import_job,
                               :filenames => [tmp.path],
                               :import_type => 'accession_csv'))
    header_error_job = Job.create_from_json(json,
                                            :repo_id => $repo_id,
                                            :user => create_nobody_user)
    header_error_job.add_file(tmp)

    expect do
      JobRunner.for(header_error_job).run
    end.to raise_error(ASpaceImport::CSVConvert::CSVSyntaxException, /accession_number_1/)

    output_stream, = header_error_job.get_output_stream
    output = output_stream.read
    expect(output).to include('Unrecognized CSV headers: accession_number_1')
    expect(output).not_to include('Trace:')
    expect(output).not_to include('#<CSVSyntaxException')
  end

end
