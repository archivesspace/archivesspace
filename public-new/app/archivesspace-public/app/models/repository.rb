class Repository < Struct.new(:code, :name)

  def self.from_json(json)
    new(json['repo_code'], json['name'])
  end

end
