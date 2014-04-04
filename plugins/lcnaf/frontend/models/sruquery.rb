class SRUQuery

  def self.name_search(family_name, given_name)
    new({ 'local.FamilyName' => family_name, 'local.FirstName' => given_name })
  end


  def self.lccn_search(lccns)
    new({ 'local.LCCN' => lccns.join(' ')})
  end


  def initialize(query, relation = 'any')
    @query = query
    @fields = query.keys 
    @relation = relation
    @boolean = 'and'
  end


  def query_string
    @query.to_s
  end


  def clean(query)
    query = query.join(' ') if query.is_a?( Array ) 
    query.gsub('"', '')
  end


  def to_s
    @fields.map {|field| "#{field} #{@relation} \"#{clean(@query[field])}\""}.
           join(" #{@boolean} ")
  end

end
