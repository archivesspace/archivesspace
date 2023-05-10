require 'java'
require 'saxon-rb'
require 'stringio'


java_import Java::org::apache::fop::apps::FopFactory
java_import Java::org::apache::fop::apps::Fop
java_import Java::org::apache::fop::apps::MimeConstants



class ASFop

  import javax.xml.transform.stream.StreamSource
  import javax.xml.transform.TransformerFactory
  import javax.xml.transform.sax.SAXResult


  attr_accessor :source
  attr_accessor :output
  attr_accessor :xslt

  def initialize(source, output= nil, pdf_image)
    @source = source
    @output = output ? output : ASUtils.tempfile('fop.pdf')
    if pdf_image.nil?
      @pdf_image = "file:///" + File.absolute_path(StaticAssetFinder.new(File.join('stylesheets')).find('ArchivesSpaceLogo_for_pdf.png'))
    else
      @pdf_image = pdf_image
    end
    @xslt = File.read( StaticAssetFinder.new(File.join('stylesheets')).find('as-ead-pdf.xsl'))
    @config = java.io.File.new(StaticAssetFinder.new(File.join('stylesheets')).find('fop-config.xml'))
  end

  def saxon_processor
    @saxon_processor ||= Saxon::Processor.create
  end

  def to_fo(sax_handler)
    transformer = saxon_processor.xslt_compiler.compile(Saxon::Source.create(File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf.xsl')))
    sax_destination = Saxon::S9API::SAXDestination.new(sax_handler)
    input = saxon_processor.document_builder.build(Saxon::Source.create(@source))
    params = {"pdf_image" => @pdf_image}
    transformer.apply_templates(input, {
      global_parameters: params,
      global_context_item: input
    }).to_destination(sax_destination)
  end

  def fop_processor
    fopfac = FopFactory.newInstance(@config)
    fopfac.newFop(MimeConstants::MIME_PDF, @output.to_outputstream)
  end

  # returns a temp file with the converted PDF
  def to_pdf
    begin
      to_fo(fop_processor.getDefaultHandler)
    ensure
      @output.close
    end
    @output
  end

  def to_pdf_stream
    begin
      to_fo(fop_processor.getDefaultHandler)
      @output.rewind
      @output.read
    ensure
      @output.close
      @output.unlink
    end
  end

end
