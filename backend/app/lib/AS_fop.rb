require 'java'
require 'saxon-xslt'
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

  def initialize(source, output= nil)  
   @source = source
   @output = output ? output : ASUtils.tempfile('fop.pdf') 
   @xslt = File.read( StaticAssetFinder.new(File.join('stylesheets')).find('as-ead-pdf.xsl')) 
  end


  def to_fo
    transformer = Saxon.XSLT(@xslt, system_id: File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf.xsl') )
    transformer.transform(Saxon.XML(@source)).to_s
  end

  # returns a temp file with the converted PDF
  def to_pdf
    begin 
      fo = StringIO.new(to_fo).to_inputstream
      fopfac = FopFactory.newInstance
      fopfac.setBaseURL( File.join(ASUtils.find_base_directory, 'stylesheets') ) 
      fop = fopfac.newFop(MimeConstants::MIME_PDF, @output.to_outputstream) 
      transformer = TransformerFactory.newInstance.newTransformer()
      res = SAXResult.new(fop.getDefaultHandler)
      transformer.transform(StreamSource.new(fo), res)
    ensure
     @output.close
    end
    @output 
  end
  
  def to_pdf_stream
    begin 
      fo = StringIO.new(to_fo).to_inputstream  
      fopfac = FopFactory.newInstance
      fopfac.setBaseURL( File.join(ASUtils.find_base_directory, 'stylesheets') ) 
      fop = fopfac.newFop(MimeConstants::MIME_PDF, @output.to_outputstream) 
      transformer = TransformerFactory.newInstance.newTransformer()
      res = SAXResult.new(fop.getDefaultHandler)
      transformer.transform(StreamSource.new(fo), res)
      @output.rewind
      @output.read
    ensure
     @output.close
     @output.unlink 
    end
  end

end
