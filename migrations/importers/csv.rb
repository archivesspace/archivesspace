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
    @swap['extent_type'] = {"linear feet" => "linear_feet",
                           "linear foot" => "linear_feet",
                           "computer files" => "cassettes",
                           "folder" => "cassettes",
                           "megabytes" => "cassettes",
                           "optical disk (DVD)" => "cassettes"
           }

    super
    
  end
  
  def run
    
    CSV.foreach(@src) do |row|
      
      if @headers.empty?
        @headers = row
        bad_headers = []
        @headers.each {|h| bad_headers << h unless h.match /^[a-z]*_[a-z0-9_]*$/ }
        if !bad_headers.empty?
          raise CSVSyntaxException.new(:bad_headers, bad_headers)
        end
      else
        parse_row(row)
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

    # Hacks to make things work for now
    val = @swap[header][val] if @swap.has_key? header and @swap[header].has_key? val
    val.sub!(/^([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{4})$/, '\2/\1/\3}') if header == 'accession_accession_date'    
    
    val = nil if val == 'NULL'
    with_receivers_for header do |r|
      r << val
    end
  end
  
  def with_receivers_for(header)
    
    ASpaceImport::Crosswalk.entries.each do |key, xdef|
      next unless xdef && xdef.has_key?('properties') && !xdef['properties'].nil?
      # rec_type = xdef.has_key?('record_type') ? xdef['record_type'] : entry
      if (prop_def = xdef['properties'].find {|p| p[1].has_key?('header') && p[1]['header'] == header})

        prop_name = prop_def.first

        json = get_queued_or_new(key)
        yield json.receivers.by_name(prop_name)        
      end
    end 
  end


  def get_queued_or_new(key)
    if (json = @parse_queue.find {|j| j.class.model_key == key })  
      
      json
    else
      @parse_queue.push(ASpaceImport::Crosswalk.models[key].new)

      @parse_queue.last
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


    

