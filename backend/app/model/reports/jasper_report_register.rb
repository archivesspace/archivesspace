require_relative 'jasper_report'
require_relative 'jdbc_report'
require_relative 'json_report'


class JasperReportRegister

  # this registers the reports so they work in the URI
  def self.register_reports
    begin 
      Array(StaticAssetFinder.new('reports').find("report_config.yml")).each do |config|
        begin 
          yml = YAML.load_file(config)
          self.register_report(yml) 
        end 
      end
    rescue NotFoundException
      $stderr.puts("NO JASPER REPORTS FOUND")
    end
  end

  def self.register_report(opts)
        # futz to get the class name correct
        if opts["report_type"] == 'json'
          ancestor = Object.const_get( "JSONReport" )
        else
          ancestor = Object.const_get( "JDBCReport")
        end
         
        report = "#{opts["uri_suffix"].split("_").map { |w| w.capitalize }.join }Report"
        klass = Object.const_set( report, Class.new(ancestor) )
        klass.send( :register_report, opts) 
  end

end
