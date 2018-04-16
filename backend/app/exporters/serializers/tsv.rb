ASpaceExport::serializer :tsv do
  
  def serialize(obj, opts = {})

    tsv = obj.headers.join("\t") << "\r"
    obj.rows.each do |r|
      tsv << r.join("\t") << "\r"
    end
    
    tsv
    
  end
end
