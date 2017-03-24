require 'axlsx'

class XLSXResponse

  MAX_WORKSHEET_TITLE_SIZE = 31

  def initialize(report, params = {})
    @report = report

    @p = Axlsx::Package.new
    @wb = @p.workbook

    generate_report
  end

  def generate_report
    report_name = @report.class.name[0,MAX_WORKSHEET_TITLE_SIZE]
    @wb.add_worksheet(:name => report_name) do |sheet|
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
