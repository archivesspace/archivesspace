require 'spec_helper'

describe PdfController, type: :controller do
  before(:all) do
    @repo = create(:repo, repo_code: "pdf_test_#{Time.now.to_i}", publish: true)
    set_repo @repo
    @resource = create(:resource, title: "PDF Test Resource", publish: true)
    run_indexers
  end

  describe 'resource action' do
    before(:each) do
      @mock_pdf_file = Tempfile.new(['test', '.pdf'])
      @mock_pdf_file.write('%PDF-1.4 mock pdf content')
      @mock_pdf_file.rewind
      mock_pdf = instance_double(FindingAidPDF,
        generate: @mock_pdf_file,
        suggested_filename: 'Test_Resource.pdf'
      )
      allow(FindingAidPDF).to receive(:new).and_return(mock_pdf)
    end

    after(:each) do
      @mock_pdf_file.close
      @mock_pdf_file.unlink if File.exist?(@mock_pdf_file.path)
    rescue
      # File may already be unlinked by controller
    end

    it 'generates a PDF with correct response headers' do
      post(:resource, params: { rid: @repo.id, id: @resource.id })

      aggregate_failures 'returns a successful response' do
        expect(response).to have_http_status(200)
      end

      aggregate_failures 'sets Content-Type header to application/pdf' do
        expect(response.headers['Content-Type']).to eq('application/pdf')
      end

      aggregate_failures 'sets Content-Length header' do
        expect(response.headers['Content-Length']).to be_present
        expect(response.headers['Content-Length'].to_i).to be > 0
      end

      aggregate_failures 'sets Content-Disposition header with attachment and filename' do
        content_disposition = response.headers['Content-Disposition']
        expect(content_disposition).to start_with('attachment')
        expect(content_disposition).to include('filename=')
        expect(content_disposition).to include('.pdf')
      end

      aggregate_failures 'sets Content-Disposition header with RFC 5987 filename* parameter' do
        content_disposition = response.headers['Content-Disposition']
        expect(content_disposition).to include("filename*=UTF-8''")
      end

      aggregate_failures 'sets X-Content-Type-Options header to nosniff' do
        expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      end
    end
  end
end
