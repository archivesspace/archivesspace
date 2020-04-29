# ANW-267:
# This class has the same purpose as ASFop: Turn an XML document into a PDF via Apache FOP.
# However, due to issues with FOP generating garbled PDF in Windows when running under JRuby, this class calls FOP externally, using system(), bypassing JRuby.

require 'saxon-rb'
require 'stringio'

class ASFopExternal

  attr_accessor :source
  attr_accessor :output
  attr_accessor :xslt

  def initialize(source, job, pdf_image)
   @source = source
   @fo = ASUtils.tempfile('pdf.xml')
   @output_path = ASUtils.tempfile_name('fop.pdf')
   if pdf_image.nil?
     @pdf_image = "file:///" + File.absolute_path(StaticAssetFinder.new(File.join('stylesheets')).find('archivesspace.small.png'))
   else
     @pdf_image = pdf_image
   end
   @xslt = File.read( StaticAssetFinder.new(File.join('stylesheets')).find('as-ead-pdf.xsl'))
   @config = StaticAssetFinder.new(File.join('stylesheets')).find('fop-config.xml')
   @job = job
  end

  def saxon_processor
    @saxon_processor ||= Saxon::Processor.create
  end

  def to_fo(tempfile)
    transformer = saxon_processor.xslt_compiler.compile(Saxon::Source.create(File.join(ASUtils.find_base_directory, 'stylesheets', 'as-ead-pdf.xsl')))
    transformer.apply_templates(Saxon::Source.create(@source), {"pdf_image" => @pdf_image}).serialize(tempfile)
  end

  def to_pdf
    # write fo to a tempfile
    to_fo(@fo)
    @fo.close

    # execute command to convert PDF to tempfile specified
    # our command is of the form
    # java -jar PATH_TO_FOP_JAR org.apache.fop.cli.Main -fo PATH_TO_INPUT_XML -pdf PATH_TO_OUTPUT_XML
    command = "cd #{path_to_fop_jar} #{multiple_command_operator} \"#{AppConfig[:path_to_java]}\" -jar fop.jar org.apache.fop.cli.Main -c \"#{@config}\" -fo \"#{@fo.path}\" -pdf \"#{@output_path}\" 2>&1"
    @job.write_output("Executing: #{command}")

    output = `#{command}`
    success = $?.success?

    @fo.unlink

    # return a file handle to our output file
    if success
      @job.write_output("Command output: #{output}")
      output = File.open(@output_path, "rb")
      output.close

      return output
    else
      raise "Error creating pdf: #{output}"
    end
  end

  private

    # path to fop.jar file could be a few different things, depending on whether server is running in dev or prod mode
    def path_to_fop_jar
      # On the Windows system tested, this is the branch (go up 5 levels and then into lib) expected to find the fop.jar file when running in prod mode.
      # The searching around with the other elsifs are a bit overkill, but added in to try to improve robustness
      if File.exists?("../../../../../lib/fop.jar")
        return "../../../../../lib"
      elsif File.exists?("../common/lib/fop.jar")
        return "../common/lib"
      elsif File.exists?("../lib/fop.jar")
        return "../lib"
      elsif File.exists?("../../lib/fop.jar")
        return "../../lib"
      elsif File.exists?("../../../lib/fop.jar")
        return "../../../lib"
      elsif File.exists?("../../../../lib/fop.jar")
        return "../../../../lib"
      elsif File.exists?("../../../../../../lib/fop.jar")
         return "../../../../../../lib"
      elsif File.exists?("lib/fop.jar")
        return "lib"
      else
        raise "fop.jar not found."
      end
    end

    # return shell command delimiter for OS
    def multiple_command_operator
      if RbConfig::CONFIG['host_os'] =~ /win32/
        return "&"
      else
        return ";"
      end
    end
end
