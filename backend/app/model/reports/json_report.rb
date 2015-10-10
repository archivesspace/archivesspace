require_relative 'jasper_report'

class JSONReport < JasperReport 

  def initialize(params)
    @repo_id = params[:repo_id] if params.has_key?(:repo_id) && params[:repo_id] != ""
    @base_path = File.join(self.class.report_base, self.class.name ) 
    @datasource = Tempfile.new(self.class.name + '.data')
    
    ObjectSpace.define_finalizer( self, self.class.finalize(self) ) 
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

  def default_params
    params = {} 
    params[JsonQueryExecuterFactory::JSON_DATE_PATTERN] ||= "yyyy-MM-dd"      
    params[JsonQueryExecuterFactory::JSON_NUMBER_PATTERN] ||= "#,##0.##"       
    params[JsonQueryExecuterFactory::JSON_LOCALE] ||= Locale::ENGLISH          
    params[JRParameter::REPORT_LOCALE] ||= ::Locale::US
    params["repositoryId"] = @repo_id
    params["basePath"] = @base_path
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
  
  def render(format, params = {} )
    if format == :json
      load_datasource 
      to_json
    elsif [:pdf, :html, :xlsx, :csv ].include?(format) 
      fill(params)
      self.send("to_#{format.to_s}")
    end
  end

end
