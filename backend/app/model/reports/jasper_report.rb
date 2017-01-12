require 'java'
require_relative 'report_manager'

require_relative '../../lib/static_asset_finder'

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
  attr_accessor :export_file
  attr_accessor :data_source
  attr_accessor :format

  def initialize(params, job, db)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ""
    @base_path = File.dirname(self.class.report)
    @format = params[:format] if params.has_key?(:format) && params[:format] != "" 
    ObjectSpace.define_finalizer( self, self.class.finalize(self) )
  end

  def title
    self.class.name
  end
 
  # the convention is that all report files ( primary and subreports)  will be located in
  # AS_BASE/reports/ClassNameReport

  # the convention is that the compiled primary report will be located in
  # AS_BASE/reports/ClassNameReport/ClassNameReport.jasper
  def report
    self.class.report
  end

  # this method compiles our jrxml files into jasper files
  def self.compile
    StaticAssetFinder.new('reports').find_by_extension(".jrxml").each do |jrxml|
      begin 
        JasperCompileManager.compile_report_to_file(jrxml,   jrxml.gsub(".jrxml", ".jasper"))
      rescue => e
        $stderr.puts "*" * 100
        $stderr.puts "*** JASPER REPORTS ERROR :"
        $stderr.puts "*** Unable to compile #{jrxml}"
        $stderr.puts "*** #{e.inspect}" 
        $stderr.puts "*" * 100
      end 
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

  def self.report
    StaticAssetFinder.new(report_base).find_all( self.name + ".jasper").find do |f|  
      File.basename(f, '.jasper') == self.name 
    end
  end
  
  def self.report_base
    "reports" 
  end


end
