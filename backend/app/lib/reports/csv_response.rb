require 'csv'

class CSVResponse

  def initialize(report, params = {} )
    @report = report
  end

  def each
    yield @report.headers.to_csv

    @report.each do |row|
      yield @report.headers.map{|h| row[h]}.to_csv
    end
  end

  # just added for the generic response
  def generate
    output = "" 
    self.each { |r| output << r } 
    output
  end

end
