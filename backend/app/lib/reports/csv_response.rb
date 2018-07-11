require 'csv'
require 'nokogiri'

class CSVResponse

  def initialize(report, params = {} )
    @report = report
    @html_report = params[:html_report].call
  end

  def generate
    return @report.to_csv if @report.template.include? 'assessment'

    doc = config_report
    if @report.template.include? 'generic_listing'
      generic_report_parsing(doc)
    else
      specific_report_parsing(doc)
    end
  end

  def config_report
    Nokogiri::XML(@html_report) do |config|
      config.strict.noblanks
    end
  end

  def generic_report_parsing(doc)
    output = []
    doc.search('table[@class="report-listing"]').each do |rec|
      rec.search('tr').each do |row|
        cells = row.search('th, td').map { |cell| cell.text.strip }
        output.push(CSV.generate_line(cells))
      end
    end
    output
  end

  def specific_report_parsing(doc)
    output = []
    sup_str = []
    heading = ''
    out_head = []
    count = 0
    doc.search('div[@class="report-record"]').each do |rec|
      int_arr = []
      out_hash = {}
      title = ''
      out_hash['identifier'] = rec.at('div[@class="identifier"]').text
      title = rec.at('div[@class="record-title"]')
      out_hash['recordTitle'] = title.xpath('text()').text if !title.nil?
      rec.search('dl').each do |row|
        out_hash.merge!(Hash[*row.search('dt, dd').map { |cell| cell.text.strip }])
      end
      sup_str = out_hash.map { |k, v| "#{v}" }.join(',')
      heading = sup_str if count == 0
      sub_rep = {}
      rec.search('section').each do |sec|
        ctr = 0
        sub_rep_arr = []
        keys = []
        sec.search('tr').each do |row|
          arr = row.search('th, td').map { |cell| cell.text.strip }
          if !arr.empty?
            if ctr == 0
              keys = arr
              heading = out_hash.map { |k, v| "#{k}" }.join(',') + ',' + 'Type' + ',' + keys.each { |v| "#{v}" }.join(',')
            elsif ctr > 0
              sub_rep_arr.push(Hash[ *(0...keys.size()).inject([]) { |array, ix| array.push(keys[ix], arr[ix]) } ])
            end
          end
          ctr += 1
        end
        sub_rep_arr.each do | ele |
          int_arr.push("#{sup_str}" + ',' + sec.at('h3').text + ',' + ele.map { |k, v| "#{v}" }.join(','))
        end
      end
      count += 1
      if int_arr.length > 0
        int_arr.each do | piece |
          output.push("#{piece}" + "\n")
        end
      else
        output.push("#{sup_str}" + "\n")
      end
    end
    if output.empty?
      doc.search('div[@class="titlepage"]').each do |rec|
        out_hash = {}
        out_hash['title'] = rec.at('div[@class="title"]').text
        rec.search('dl').each do |row|
          out_hash.merge!(Hash[*row.search('dt, dd').map { |cell| cell.text.strip }])
        end
        heading = 'Report' + ',' + out_hash.keys.each { |v| "#{v}" }.join(',')
        sup_str = out_hash.map { |k, v| "#{v}" }.join(',')
        output.push("#{sup_str}" + "\n")
      end
      puts "#{heading}"
      output.unshift("#{heading}" + "\n")
    else
      output.unshift("#{heading}" + "\n")
    end
  end
end
