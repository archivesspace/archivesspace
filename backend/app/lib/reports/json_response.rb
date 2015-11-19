class JSONResponse

  def initialize(report, params = {} )
    @report = report
  end

  def each
    yield "["
    first = true
    @report.each do |row|
      if first
        first = false
      else
        yield ","
      end
      yield row.to_json
    end
    yield "]"
  end

  def generate
    output = "" 
    self.each { |r| output << r } 
  end
end
