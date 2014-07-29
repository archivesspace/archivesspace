require 'axlsx'

class XLSXResponse

  def initialize(report, params = {})
    @report = report

    @p = Axlsx::Package.new
    @wb = @p.workbook

    generate_report
  end

  def generate_report
    @wb.add_worksheet(:name => @report.class.name) do |sheet|
      sheet.add_row @report.headers
      @report.each do |row|
        sheet.add_row @report.headers.map{|h| row[h]}
      end
    end
  end

  def to_stream
    @p.to_stream
  end

  def generate
    @p.to_stream
  end

end
