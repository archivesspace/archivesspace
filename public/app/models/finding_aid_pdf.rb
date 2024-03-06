require 'tempfile'

class FindingAidPDF

  DEPTH_1_LEVELS = ['collection', 'recordgrp', 'series']
  DEPTH_2_LEVELS = ['subgrp', 'subseries', 'subfonds']

  attr_reader :repo_id, :resource_id, :archivesspace, :base_url, :repo_code

  def initialize(repo_id, resource_id, archivesspace_client, base_url)
    @repo_id = repo_id
    @resource_id = resource_id
    @archivesspace = archivesspace_client
    @base_url = base_url

    @resource = archivesspace.get_record("/repositories/#{repo_id}/resources/#{resource_id}")
    @ordered_records = archivesspace.get_record("/repositories/#{repo_id}/resources/#{resource_id}/ordered_records")

    # make sure finding aid title isn't only like /^\n$/
    if @resource.finding_aid['title'] and @resource.finding_aid['title'] =~ /\w/
      @short_title = @resource.finding_aid['title'].lstrip.split("\n")[0].strip
    end
  end

  def suggested_filename
    # Use the EAD ID.  If that's missing, use the 4-part identifier
    filename = (@resource.ead_id || @resource.four_part_identifier.reject(&:blank?).join('_'))

    # no spaces, please.
    filename.gsub(' ', '_') + '.pdf'
  end

  def short_title
    @short_title || suggested_filename
  end

  def source_file
    # We'll use the original controller so we can find and render the PDF
    # partials, but just for its ERB rendering.
    renderer = PdfController.new
    start_time = Time.now

    @repo_code = @resource.repository_information.fetch('top').fetch('repo_code')

    # .length == 1 would be just the resource itself.
    has_children = @ordered_records.entries.length > 1

    out_html = Tempfile.new

    # Use a NokogiriPushParser-based
    writer = Nokogiri::XML::SAX::PushParser.new(XMLCleaner.new(out_html))
    writer.write(renderer.render_to_string partial: 'header', layout: false, :locals => {:record => @resource})

    writer.write(renderer.render_to_string partial: 'titlepage', layout: false, :locals => {:record => @resource})

    # Drop the resource and filter the AOs
    toc_aos = @ordered_records.entries.drop(1).select {|entry|
      if entry.depth == 1
        DEPTH_1_LEVELS.include?(entry.level)
      elsif entry.depth == 2
        DEPTH_2_LEVELS.include?(entry.level)
      else
        false
      end
    }

    writer.write(renderer.render_to_string partial: 'toc', layout: false, :locals => {:resource => @resource, :has_children => has_children, :ordered_aos => toc_aos})

    writer.write(renderer.render_to_string partial: 'resource', layout: false, :locals => {:record => @resource, :has_children => has_children})

    page_size = 50

    @ordered_records.entries.drop(1).each_slice(page_size) do |entry_set|
      if AppConfig[:pui_pdf_timeout] && AppConfig[:pui_pdf_timeout] > 0 && (Time.now.to_i - start_time.to_i) >= AppConfig[:pui_pdf_timeout]
        raise TimeoutError.new("PDF generation timed out.  Sorry!")
      end

      uri_set = entry_set.map(&:uri)
      record_set = archivesspace.search_records(uri_set, {}, true).records


      unprocessed_record_list = record_set.zip(entry_set)
      ao_list = []

      # tuple looks like [ArchivalObject, Entry]
      unprocessed_record_list.each_with_index do |tuple, i|
        record = tuple[0]
        next_record = unprocessed_record_list[i + 1][0] rescue nil

        next unless record.is_a?(ArchivalObject)

        if next_record && record.uri == next_record.parent_for_md_mapping
          has_children = true
        else
          has_children = false
        end

        tuple[2] = has_children

        ao_list.push(tuple)
      end


      ao_list.each do |record, entry, is_parent|
        writer.write(renderer.render_to_string partial: 'archival_object', layout: false, :locals => {:record => record, :level => entry.depth, :is_parent => is_parent})
      end
    end

    writer.write(renderer.render_to_string partial: 'footer', layout: false, :locals => {:record => @resource})
    out_html.close

    out_html
  end

  def generate
    java_import com.lowagie.text.pdf.BaseFont;
    out_html = source_file

    pdf_file = Tempfile.new
    pdf_file.close

    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new
    resolver = renderer.getFontResolver

    # ANW-1075: Use Kurinto, followed by Noto Serif by defaults for open source compatibility and Unicode support for Latin, Cyrillic and Greek alphabets
    # Additional fonts can be specified via config file and added via plugin

    if AppConfig[:plugins].include?("custom-pui-pdf-font")
      font_paths = AppConfig[:pui_pdf_font_files].map do |font|
        Rails.root.to_s + "/../plugins/custom-pui-pdf-font/public/app/assets/fonts/#{font}"
      end
    else
      font_paths = AppConfig[:pui_pdf_font_files].map do |font|
        Rails.root.to_s + "/app/assets/fonts/#{font}"
      end
    end

    font_paths.each do |font_path|
      resolver.addFont(
        font_path,
        "Identity-H",
        true
      );
    end

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
