class AbstractReport
  def initialize(*args)
  end

  def title
    self.class.name
  end

  def template
    :'reports/_listing'
  end

  def orientation
    'landscape'
  end

  def processor
    {}
  end

  def query(db)
    raise "Please specific a query to return your reportable results"
  end

  def each
    DB.open do |db|
      query(db).each do |row|
        yield(Hash[headers.map { |h|
          val = (processor.has_key?(h))?processor[h].call(row):row[h.intern]
          [h, val]
        }])
      end
    end
  end
end