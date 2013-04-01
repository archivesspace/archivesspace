class JSONResponse

  def initialize(report)
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

end