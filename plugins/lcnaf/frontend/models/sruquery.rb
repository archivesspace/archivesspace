class SRUQuery

  def self.name_search(family_name, given_name )
    query = { 'local.FamilyName' => family_name}
    query['local.FirstName'] = given_name unless ( given_name.nil? or given_name.empty? )
    new( query )
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



  def clean(query)
    query = query.join(' ') if query.is_a?( Array ) 
    query.gsub('"', '')
  end


  def to_s
    @fields.map { |field| "#{field} #{@relation} \"#{clean(@query[field])}\"" unless @query[field].empty? }.
           compact.join(" #{@boolean} ")
  end

end
