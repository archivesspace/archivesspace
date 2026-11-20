# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe JobsHelper do
  describe '#job_download_files' do
    def job_with(job_type, job_data)
      job = JSONModel(:job).from_hash({ uri: '/jobs/1', job_type: job_type })
      allow(job).to receive(:job).and_return(job_data)
      job
    end

    it 'pairs each file with the extension of its original filename' do
      job = job_with('import_job', { 'filenames' => ['ead.xml', 'data.CSV'] })

      expect(helper.job_download_files(job, [10, 11])).to eq([[10, '.xml'], [11, '.CSV']])
    end

    it 'gives no extension to a filename that has none' do
      job = job_with('import_job', { 'filenames' => ['myEAD', '.xml'] })

      expect(helper.job_download_files(job, [10, 11])).to eq([[10, nil], [11, nil]])
    end

    it 'gives no extension to files without a matching filename' do
      job = job_with('import_job', { 'filenames' => ['ead.xml'] })

      expect(helper.job_download_files(job, [10, 11])).to eq([[10, '.xml'], [11, nil]])
    end

    it 'uses the single filename of jobs that record one' do
      job = job_with('top_container_linker_job', { 'filename' => 'links.csv' })

      expect(helper.job_download_files(job, [3])).to eq([[3, '.csv']])
    end

    it 'gives no extension to jobs that record no filenames' do
      job = job_with('report_job', { 'format' => 'csv' })

      expect(helper.job_download_files(job, [5])).to eq([[5, nil]])
    end

    it 'hides the uploaded spreadsheet of a bulk import once its report exists' do
      job = job_with('bulk_import_job', { 'filename' => 'sheet.xlsx', 'format' => 'csv' })

      # the report must not inherit the spreadsheet's extension
      expect(helper.job_download_files(job, [1, 2])).to eq([[2, nil]])
    end

    it 'keeps the uploaded spreadsheet of a bulk import when it is the only file' do
      job = job_with('bulk_import_job', { 'filename' => 'sheet.xlsx', 'format' => 'csv' })

      expect(helper.job_download_files(job, [1])).to eq([[1, '.xlsx']])
    end
  end
end
