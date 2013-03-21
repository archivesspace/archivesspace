require 'csv'

class CSVResponse

  def initialize(report)
    @report = report
  end

  def each
    yield @report.headers.to_csv

    @report.each do |row|
      yield @report.headers.map{|h| row[h]}.to_csv
    end
  end

end