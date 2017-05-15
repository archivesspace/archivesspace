class PdfController <  ApplicationController

  def resource
    repo_id = params.fetch(:rid, nil)
    resource_id = params.fetch(:id, nil)

    pdf = FindingAidPDF.new(repo_id, resource_id, archivesspace, "#{request.protocol}#{request.host_with_port}")
    pdf_file = pdf.generate

    respond_to do |format|
      format.all do
        fh = File.open(pdf_file.path, "r")
        self.headers["Content-type"] = "application/pdf"
        self.response_body = Enumerator.new do |y|
          begin
            while chunk = fh.read(4096)
              y << chunk
            end
          ensure
            fh.close
            pdf_file.unlink
          end
        end
      end
    end

  end

end
