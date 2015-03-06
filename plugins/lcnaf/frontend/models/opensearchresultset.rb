require 'asutils'

class OpenSearchResultSet
  attr_reader :total_results
  attr_reader :start_index
  attr_reader :items_per_page
  attr_reader :entries

  def initialize(response_body, query)
    @entries = []
    @query = query

    json = ASUtils.json_parse(response_body)
    json.each do |atom_el|
      next unless atom_el.is_a? Array

      case atom_el[0]
      when 'opensearch:totalResults'
        @total_results = atom_el[2].to_i
      when 'opensearch:startIndex'
        @start_index = atom_el[2].to_i
      when 'opensearch:itemsPerPage'
        @items_per_page = atom_el[2].to_i
      when 'atom:entry'
        process_entry(atom_el[2..-1])
      end
    end

    @page = (@start_index / @items_per_page) + 1
  end


  def process_entry(entry)
    e = {}

    entry.each do |seg|
      case seg[0]
      when 'atom:title'
        e['title'] = seg[2]
      when 'atom:id'
        e['lccn'] = seg[2].sub(/.*names\//, '')
      when 'atom:link'
        e['uri'] = seg[1]['href'] unless seg[1]['type']
      end
    end

    @entries << e
  end

  def last_record_index
    [@start_index.to_i + @items_per_page.to_i - 1, @total_results.to_i].min
  end


  def at_start?
    @start_index.to_i < 2
  end


  def at_end?
    last_record_index == @total_results.to_i
  end



  def to_json
    ASUtils.to_json(:records => @entries,
                    :first_record_index => @start_index.to_i,
                    :last_record_index => last_record_index,
                    :at_start => at_start?,
                    :at_end => at_end?,
                    :page => @page,
                    :query => @query,
                    :hit_count => @total_results.to_i,
                    :records_per_page => @items_per_page.to_i
                    )
  end

end
