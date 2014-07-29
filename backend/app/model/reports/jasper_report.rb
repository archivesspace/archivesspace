require 'java'
require_relative 'report_manager'
require 'tempfile'
require 'rjack-jackson'

java_import java.util.Locale

java_import Java::net::sf::jasperreports::engine::JRException
java_import Java::net::sf::jasperreports::engine::JRParameter
java_import Java::net::sf::jasperreports::engine::JasperExportManager
java_import Java::net::sf::jasperreports::engine::JasperFillManager
java_import Java::net::sf::jasperreports::engine::JasperCompileManager
java_import Java::net::sf::jasperreports::engine::util::JRLoader
java_import Java::net::sf::jasperreports::export::SimpleExporterInput
java_import Java::net::sf::jasperreports::export::SimpleWriterExporterOutput
java_import Java::net::sf::jasperreports::export::SimpleOutputStreamExporterOutput
java_import Java::net::sf::jasperreports::export::SimpleXlsxReportConfiguration
java_import Java::net::sf::jasperreports::engine::export::JRCsvExporter
java_import Java::net::sf::jasperreports::engine::export::ooxml::JRXlsxExporter
java_import Java::net::sf::jasperreports::engine::query::JsonQueryExecuterFactory
java_import Java::org::apache::commons::lang::StringUtils


class JasperReport 
  include ReportManager::Mixin
  include Java

  attr_accessor :jrprint
  attr_accessor :datasource
  attr_accessor :export_file

  def initialize(params)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ""
    @datasource = Tempfile.new(self.class.name + '.data')
    
    ObjectSpace.define_finalizer( self, self.class.finalize(self) ) 
  end

  def title
    self.class.name
  end
 
  # the convention is that all report files ( primary and subreports)  will be located in
  # AS_BASE/reports/ClassNameReport
  def report_base
    File.join('reports', self.class.name )
  end

  # the convention is that the compiled primary report will be located in
  # AS_BASE/reports/ClassNameReport/ClassNameReport.jasper
  def report 
    StaticAssetFinder.new(report_base).find( self.class.name + ".jasper")
  end

  # there are several ways to attach data to your jasper report. most of them
  # don't seem to work very well. One that does it to add a file uri to the
  # json.datasource property that's passed as a param. since this works, it
  # will be the default.  
  def load_datasource
    @datasource.write(query.to_json)
    @datasource.rewind # be kind
    @datasource.path
  end

  # this is where we load the data. it most likely will be a sequel query 
  def query
    { :locations => [] }
  end

  # this method compiles our jrxml files into jasper files
  def compile
    StaticAssetFinder.new(report_base).find_by_extension(".jrxml").each do |jrxml|
      JasperCompileManager.compile_report_to_file(jrxml,   jrxml.gsub(".jrxml", ".jasper"))
    end
  end
 
  def default_params
    params = {} 
    params[JsonQueryExecuterFactory::JSON_DATE_PATTERN] ||= "yyyy-MM-dd"      
    params[JsonQueryExecuterFactory::JSON_NUMBER_PATTERN] ||= "#,##0.##"       
    params[JsonQueryExecuterFactory::JSON_LOCALE] ||= Locale::ENGLISH          
    params[JRParameter::REPORT_LOCALE] ||= ::Locale::US
    params
  end
  
  def fill( params = {} )
    params.merge!(default_params) 
    params["net.sf.jasperreports.json.source"] = load_datasource
    
    @jrprint =  JasperFillManager.fill_report(report, java.util.HashMap.new(params) )
  
  end

  def to_pdf
     JasperExportManager.export_report_to_pdf(@jrprint)
  end

  def to_html
    @export_file = Tempfile.new("location.html")
    JasperExportManager.export_report_to_html_file(@jrprint, @export_file.path)
    @export_file.rewind 
    @export_file.read.to_java_bytes 
  end

  def to_csv
    exporter = JRCsvExporter.new
    exporter.exporter_input = SimpleExporterInput.new(@jrprint)
    @export_file = Tempfile.new("location.csv")
    exporter.exporter_output = SimpleWriterExporterOutput.new(@export_file.to_outputstream)
    exporter.export_report
    @export_file.rewind 
    @export_file.read.to_java_bytes 
  end
 
  def to_xlsx
    exporter = JRXlsxExporter.new
    exporter.exporter_input = SimpleExporterInput.new(@jrprint)
    @export_file = Tempfile.new("location.xlsx")
    exporter.exporter_output = SimpleOutputStreamExporterOutput.new(@export_file.to_outputstream)
    configuration = SimpleXlsxReportConfiguration.new 
    configuration.one_page_per_sheet = false 
    exporter.configuration = configuration
    exporter.export_report
    @export_file.rewind 
    @export_file.read.to_java_bytes 

  end

  def to_json
    @datasource.read.to_java_bytes
  end
  
  def render(format)
    if format == :json
      load_datasource 
      to_json
    elsif [:pdf, :html, :xlsx, :csv ].include?(format) 
      compile
      fill
      self.send("to_#{format.to_s}")
    end
  end

  # this makes sure all our tempfiles get unlinked...
  def self.finalize(obj)
    proc { 
      unless obj.export_file.nil?
        obj.export_file.close!
      end 
      obj.datasource.close!
    } 
  end
end
