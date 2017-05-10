require 'tempfile'

class PdfController <  ApplicationController

  DEPTH_1_LEVELS = ['collection', 'recordgrp', 'series']
  DEPTH_2_LEVELS = ['subgrp', 'subseries', 'subfonds']

  def resource
    repo_id = params.fetch(:rid, nil)
    resource_id = params.fetch(:id, nil)

    resource = archivesspace.get_record("/repositories/#{repo_id}/resources/#{resource_id}")
    ordered_records = archivesspace.get_record("/repositories/#{repo_id}/resources/#{resource_id}/ordered_records")

    # .length == 1 would be just the resource itself.
    has_children = ordered_records.entries.length > 1

    out_html = Tempfile.new
    out_html.write(render_to_string partial: 'header', layout: false)

    out_html.write(render_to_string partial: 'titlepage', layout: false, :locals => {:record => resource})

    toc_aos = ordered_records.entries.select {|entry|
      if entry.uri =~ /archival_object/
        if entry.depth == 1
          DEPTH_1_LEVELS.include?(entry.level)
        elsif entry.depth == 2
          DEPTH_2_LEVELS.include?(entry.level)
        else
          false
        end
      else
        false
      end
    }

    out_html.write(render_to_string partial: 'toc', layout: false, :locals => {:resource => resource, :has_children => has_children, :ordered_aos => toc_aos})

    out_html.write(render_to_string partial: 'resource', layout: false, :locals => {:record => resource, :has_children => has_children})

    page_size = 50
    ordered_records.entries.each_slice(page_size) do |entry_set|
      uri_set = entry_set.map(&:uri)
      record_set = archivesspace.search_records(uri_set, {}, true).records

      record_set.zip(entry_set).each do |record, entry|
        next unless record.is_a?(ArchivalObject)

        out_html.write(render_to_string partial: 'archival_object', layout: false, :locals => {:record => record, :level => entry.depth})
      end
    end

    out_html.write(render_to_string partial: 'footer', layout: false)
    out_html.close

    XMLCleaner.new.clean(out_html.path)

    pdf_file = Tempfile.new
    pdf_file.close

    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new
    renderer.set_document(java.io.File.new(out_html.path))

    # FIXME: We'll need to test this with a reverse proxy in front of it.
    renderer.shared_context.base_url = "#{request.protocol}#{request.host_with_port}"

    renderer.layout

    pdf_output_stream = java.io.FileOutputStream.new(pdf_file.path)
    renderer.create_pdf(pdf_output_stream)
    pdf_output_stream.close

    out_html.unlink

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
