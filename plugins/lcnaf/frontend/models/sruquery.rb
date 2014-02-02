class SRUQuery

  def self.name_search(query_string)
    new(query_string, ['local.FamilyName', 'local.FirstName'])
  end


  def self.lccn_search(lccns)
    new(lccns.join(" "), ['local.LCCN'])
  end


  def initialize(query, fields, relation = 'any')
    @query = clean(query)
    @fields = fields
    @relation = relation
    @boolean = 'or'
  end


  def query_string
    @query
  end


  def clean(query)
    query.gsub('"', '')
  end


  def to_s
    @fields.map {|field| "#{field} #{@relation} \"#{@query}\""}.
           join(" #{@boolean} ")
  end

end
