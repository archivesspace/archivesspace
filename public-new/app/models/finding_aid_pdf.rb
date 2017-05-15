require 'tempfile'

class FindingAidPDF

  DEPTH_1_LEVELS = ['collection', 'recordgrp', 'series']
  DEPTH_2_LEVELS = ['subgrp', 'subseries', 'subfonds']

  attr_reader :repo_id, :resource_id, :archivesspace, :base_url

  def initialize(repo_id, resource_id, archivesspace_client, base_url)
    @repo_id = repo_id
    @resource_id = resource_id
    @archivesspace = archivesspace_client
    @base_url = base_url
  end

  def generate
    # We'll use the original controller so we can find and render the PDF
    # partials, but just for its ERB rendering.
    renderer = PdfController.new

    resource = archivesspace.get_record("/repositories/#{repo_id}/resources/#{resource_id}")
    ordered_records = archivesspace.get_record("/repositories/#{repo_id}/resources/#{resource_id}/ordered_records")

    # .length == 1 would be just the resource itself.
    has_children = ordered_records.entries.length > 1

    out_html = Tempfile.new
    out_html.write(renderer.render_to_string partial: 'header', layout: false, :locals => {:record => resource})

    out_html.write(renderer.render_to_string partial: 'titlepage', layout: false, :locals => {:record => resource})

    # Drop the resource and filter the AOs
    toc_aos = ordered_records.entries.drop(1).select {|entry|
      if entry.depth == 1
        DEPTH_1_LEVELS.include?(entry.level)
      elsif entry.depth == 2
        DEPTH_2_LEVELS.include?(entry.level)
      else
        false
      end
    }

    out_html.write(renderer.render_to_string partial: 'toc', layout: false, :locals => {:resource => resource, :has_children => has_children, :ordered_aos => toc_aos})

    out_html.write(renderer.render_to_string partial: 'resource', layout: false, :locals => {:record => resource, :has_children => has_children})

    page_size = 50
    ordered_records.entries.each_slice(page_size) do |entry_set|
      uri_set = entry_set.map(&:uri)
      record_set = archivesspace.search_records(uri_set, {}, true).records

      record_set.zip(entry_set).each do |record, entry|
        next unless record.is_a?(ArchivalObject)

        out_html.write(renderer.render_to_string partial: 'archival_object', layout: false, :locals => {:record => record, :level => entry.depth})
      end
    end

    out_html.write(renderer.render_to_string partial: 'footer', layout: false)
    out_html.close

    XMLCleaner.new.clean(out_html.path)

    pdf_file = Tempfile.new
    pdf_file.close

    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new
    renderer.set_document(java.io.File.new(out_html.path))

    # FIXME: We'll need to test this with a reverse proxy in front of it.
    renderer.shared_context.base_url = base_url

    renderer.layout

    pdf_output_stream = java.io.FileOutputStream.new(pdf_file.path)
    renderer.create_pdf(pdf_output_stream)
    pdf_output_stream.close

    out_html.unlink

    pdf_file
  end
end
