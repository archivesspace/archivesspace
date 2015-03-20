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
   # WHAT A HACK! but you can't pass in a URI as a variable? jeezus.  
   filepath =  File.join(ASUtils.find_base_directory, 'stylesheets', 'as-helper-functions.xsl').gsub("\\", "/" )
   @xslt.gsub!('<xsl:include href="as-helper-functions.xsl"/>', "<xsl:include href='#{filepath}'/>" ) 
  end


  def to_fo
    transformer = Saxon.XSLT(@xslt)
    transformer.transform(Saxon.XML(@source)).to_s
  end

  # returns a temp file with the converted PDF
  def to_pdf
    begin 
      fo = StringIO.new(to_fo).to_inputstream  
      fop = FopFactory.newInstance.newFop(MimeConstants::MIME_PDF, @output.to_outputstream)
      transformer = TransformerFactory.newInstance.newTransformer()
      res = SAXResult.new(fop.getDefaultHandler)
      transformer.transform(StreamSource.new(fo), res)
    ensure
     @output.close
    end
    @output 
  end

end
