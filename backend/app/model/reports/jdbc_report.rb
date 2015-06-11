require_relative 'jasper_report'
require 'csv'
require 'json'

class JDBCReport < JasperReport 
 
  def default_params
    params = {} 
    params[JsonQueryExecuterFactory::JSON_DATE_PATTERN] ||= "yyyy-MM-dd"      
    params[JsonQueryExecuterFactory::JSON_NUMBER_PATTERN] ||= "#,##0.##"       
    params[JsonQueryExecuterFactory::JSON_LOCALE] ||= Locale::ENGLISH          
    params[JRParameter::REPORT_LOCALE] ||= ::Locale::US
    params["repositoryId"] = @repo_id.to_java(:int)
    params["basePath"] = @base_path
    params
  end
  
  def fill( params = {} )
    params.merge!(default_params) 
    DB.open(false) do |db| 
        db.pool.hold do |conn| 
          @jrprint =  JasperFillManager.fill_report(report, java.util.HashMap.new(params), conn )
        end 
    end 
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
    @export_file = Tempfile.new(SecureRandom.hex)
    exporter.exporter_output = SimpleWriterExporterOutput.new(@export_file.to_outputstream)
    exporter.export_report
    @export_file.rewind 
    @export_file.read.to_java_bytes 
  end
 
  def to_xlsx
    exporter = JRXlsxExporter.new
    exporter.exporter_input = SimpleExporterInput.new(@jrprint)
    @export_file = Tempfile.new(SecureRandom.hex)
    exporter.exporter_output = SimpleOutputStreamExporterOutput.new(@export_file.to_outputstream)
    configuration = SimpleXlsxReportConfiguration.new 
    configuration.one_page_per_sheet = false 
    exporter.configuration = configuration
    exporter.export_report
    @export_file.rewind 
    @export_file.read.to_java_bytes 

  end

  def to_json
     json = { "results" => [] }
     csv = CSV.parse(String.from_java_bytes(to_csv), :headers => true)
     csv.each do |row|
      result = {}
      row.each { |header,val| result[header.downcase] = val unless header.nil?  }
      json["results"] <<  result 
     end
     JSON(json).to_java_bytes 
  end
  
  def render(format, params = {})
    if [:pdf, :html, :xlsx, :csv, :json ].include?(format) 
      fill(params)
      self.send("to_#{format.to_s}")
    end
  end

end
