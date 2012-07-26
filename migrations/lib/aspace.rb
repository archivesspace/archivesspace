class ASpaceRecordPoster
  def post_json(record_type, json_record)
    #TODO - Work out the POST URL by the record type
    #TODO - config for ASPACE host, port, repository, auth info
    #TODO - get back an ID and confirmation from ASpace
    puts "Posting new '#{record_type}' to ASpace:" 
    puts json_record;
  end
end