
class JSONResponse

  def initialize(report, params = {} )
    @report = report
    @html_report = params[:html_report].call
  end

  def generate
    return @report.to_json if @report.template.include? 'assessment'

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
    keys = []

    doc.search('table[@class="report-listing"]').each do |rec|
      keys = rec.at('thead').search('tr').search('th').map { |th_text| th_text.text }
      if keys.empty?
        rec.search('tr').each do |row|
          output.push(Hash[*row.search('th, td').map { |cell| cell.text.strip }].to_json)
        end
      else
        rec.search('tr').each do |d|
          values = d.search('td').map { |td_text| td_text.text.strip }
          if keys.length == values.length
            out_hash = [keys,values].transpose.to_h
            output.push(out_hash.to_json)
          end
        end
      end
    end
    '[' + output.map { |s| "#{s}" }.join(', ') + ']'
  end

  def specific_report_parsing(doc)
    output = []
    doc.search('div[@class="report-record"]').each do |rec|
      out_hash = {}
      title = ''
      out_hash['identifier'] = rec.at('div[@class="identifier"]').text
      title = rec.at('div[@class="record-title"]')
      out_hash['recordTitle'] = title.xpath('text()').text if !title.nil?
      rec.search('dl').each do |row|
        out_hash.merge!(Hash[*row.search('dt, dd').map { |cell| cell.text.strip }])
      end
      rec.search('section').each do |sec|
        ctr = 0
        keys = []
        sec.search('tr').each do |row|
          if ctr % 2 == 0
            keys = row.search('th').map { |cell| cell.text.strip }
          else
            values = row.search('td').map { |cell| cell.text.strip }
            out_hash.merge!([keys,values].transpose.to_h) if keys.length == values.length
          end
          ctr += 1
        end
      end
      output.push(out_hash.to_json)
    end
    if output.empty?
      doc.search('div[@class="titlepage"]').each do |rec|
        out_hash = {}
        out_hash['title'] = rec.at('div[@class="title"]').text
        rec.search('dl').each do |row|
          out_hash.merge!(Hash[*row.search('dt, dd').map { |cell| cell.text.strip }])
        end
        output.push(out_hash.to_json)
      end
    end
    '[' + output.map { |s| "#{s}" }.join(', ') + ']'
  end
end
