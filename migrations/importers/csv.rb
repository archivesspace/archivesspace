require 'csv'

ASpaceImport::Importer.importer :csv do
  
  def initialize(opts)
    
    @src = opts[:input_file]
    @headers = []

    ASpaceImport::Crosswalk.add_link_condition(lambda { |r, json|
      
      if r.class.valid_json_types && r.class.valid_json_types.include?(json.jsonmodel_type)
        true
      else
        false
      end
    })
    
    @swap = {}
 
    super
    
  end
  
  def run
    
    i = 0
    
    CSV.foreach(@src) do |row|
      
      i = i+1
      
      if @headers.empty?
        @headers = row
        bad_headers = []
        @headers.each {|h| bad_headers << h unless h.match /^[a-z]*_[a-z0-9_]*$/ }
        if !bad_headers.empty?
          raise CSVSyntaxException.new(:bad_headers, bad_headers)
        end
      else
        parse_row(row) #unless i > 2
      end
    end

    save_all
    
  end
  
  def self.profile
    "CSV Accessions"
  end

  
  def parse_row(row)
        
    row.each_with_index do |cell, i|
      parse_cell(@headers[i], cell)
    end

    clear_parse_queue
  end

  
  def parse_cell(header, val)
    
    val = nil if val == 'NULL'

    ASpaceImport.logger.debug("PARSING HEADER: #{header} VALUE: #{val}")
    # TODO - generalize this
    val.sub!(/^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})$/, '\2/\1/\3}') if ['accession_accession_date', 'accession_cataloged_date'].include?(header) && val
    
    if ASpaceImport::Crosswalk.headers.has_key?(header)

      path = ASpaceImport::Crosswalk.headers[header].scan(/[^.]+/)
      
      json = get_queued_or_new(path.slice!(0))
              
      while path.length > 1
        subjson = get_new(path.slice!(0))
        json.receivers.for_obj(subjson) { |r| r.whitelist(subjson) } # this could be terser
      end 
      
      @parse_queue.selected.receivers.by_name(path.last) do |r|
        r << val
      end
    end 
  end

  def get_new(key)
    ASpaceImport.logger.debug "CALLING MODEL BY KEY #{key}"
    @parse_queue.push(ASpaceImport::Crosswalk.models[key].new)

    @parse_queue.selected
  end

  def get_queued_or_new(key)
    if (json = @parse_queue.find {|j| j.class.model_key == key })  
      ASpaceImport.logger.debug("Got #{json.to_s}")
      @parse_queue.select(json)
      @parse_queue.selected
    else
      get_new(key)
    end
  end
  

  class CSVSyntaxException < StandardError

    def initialize(type, element)
      @type = type
      @element = element
    end

    def to_s
      "#<:CSVSyntaxException: #{@type} => #{@element.inspect}"
    end
  end

end


    

