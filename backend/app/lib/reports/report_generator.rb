require 'java'
require 'csv'
require_relative 'rtf_generator'
require_relative 'csv_report_expander'

#java_import org.xhtmlrenderer.pdf.ITextRenderer

class ReportGenerator
  attr_accessor :report
  attr_accessor :sub_report_data_stack
  attr_accessor :sub_report_code_stack

  def initialize(report)
    @report = report
    @sub_report_data_stack = []
    @sub_report_code_stack = []
  end

  def generate(file)
    case(report.format)
    when 'json'
      generate_json(file)
    when 'html'
      generate_html(file)
    when 'pdf'
      generate_pdf(file)
    when 'rtf'
      generate_rtf(file)
    else
      generate_csv(file)
    end
  end

  def generate_json(file)
    data = {}
    data[:info] = nil
    data[:records] = report.get_content
    data[:info] = report.info
    json = ASUtils.to_json(data)
    file.write(json)
  end

  def generate_html(file)
    file.write(do_render('report.erb'))
  end

  def generate_pdf(file)
    output_stream = java.io.FileOutputStream.new(file.path)
    xml = ASUtils.tempfile('xml_report_')
    xml.write(clean_invalid_xml_chars(do_render('report.erb')))
    xml.close
    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new

    renderer.set_document(java.io.File.new(xml.path))
    renderer.layout

    renderer.create_pdf(output_stream)

    xml.unlink
    output_stream.close
  end

  def generate_rtf(file)
    rtf = RtfGenerator.new(self).generate
    file.write(rtf.to_rtf)
  end

  def generate_csv(file)
    results = report.get_content
    CSV.open(file.path, 'wb') do |csv|
      report.info.each do |key, value|
        csv << [key, value]
      end
      csv << []

      begin
        rows = []
        rows.push(results[0].keys)

        results.each do |result|
          row = []
          result.each do |_key, value|
            row.push(value.is_a?(Array) ? ASUtils.to_json(value) : value)
          end
          rows.push(row)
        end

        data = nil
        if report.expand_csv
          data = CsvReportExpander.new(rows, report.job).expand_csv
        else
          data = rows
        end

        data.each do |row|
          csv << row
        end
      rescue NoMethodError
        csv << ['No results found.']
      end
    end
  end

  def xml_clean!(data)
    data_array = data.is_a?(Array) ? data : [data]
    invalid_chars = {}
    invalid_chars['"'] = '&quot;'
    invalid_chars['&'] = '&amp;'
    invalid_chars["'"] = '&apos;'
    invalid_chars['<'] = '&lt;'
    invalid_chars['>'] = '&gt;'
    data_array.each do |item|
      next unless item.is_a?(Hash)
      item.each do |_key, value|
        if value.is_a?(Array)
          xml_clean!(value)
        elsif value
          value.to_s.gsub!(/[#{invalid_chars.keys.join('')}]/) do |ch|
            invalid_chars[ch]
          end
        end
      end
    end
  end

  def clean_invalid_xml_chars(text)
    control_chars = (0...32).map(&:chr)
    valid_control_chars = [0x9, 0xA, 0xD].map(&:chr)
    text.gsub!(/[#{control_chars.join("")}]/) do |ch|
      if valid_control_chars.include?(ch)
        ch
      else
        ''
      end
    end
  end

  def do_render(file)
    renderer = ERB.new(File.read(template_path(file)))
    renderer.result(binding)
  end

  def format_sub_report(contents)
    sub_report_code_stack.push(contents.pop)
    sub_report_data_stack.push(contents)
    render = do_render('top_level_subreport.erb')
    sub_report_code_stack.pop
    sub_report_data_stack.pop
    render
  end

  def show_in_list(value)
    sub_report_code_stack.push(value.pop)
    sub_report_data_stack.push(value)
    render = do_render('nested_subreport.erb')
    sub_report_code_stack.pop
    sub_report_data_stack.pop
    render
  end

  def rtf_subreport(value)
    sub_report_code_stack.push(value.pop)
    sub_report_data_stack.push(value)
    yield(value)
    sub_report_code_stack.pop
    sub_report_data_stack.pop
  end

  def template_path(file)
    if File.exist?(File.join('app', 'views', 'reports', file))
      return File.join('app', 'views', 'reports', file)
    end

    StaticAssetFinder.new('reports').find(file)
  end

  def identifier(record)
    [t('identifier_prefix', nil), record[report.identifier_field]].compact.join(' ') if report.identifier_field
  end

  def t(key, default='')
    subreport_code = sub_report_code_stack.empty? ? nil : sub_report_code_stack.last
    special_translation = report.special_translation(key, subreport_code)
    if special_translation
      special_translation
    else
      if default == ''
        fallback = key
      else
        fallback = default
      end
      global = I18n.t("reports.translation_defaults.#{key}", :default => fallback)
      if sub_report_code_stack.empty?
        I18n.t("reports.#{report.code}.#{key}", :default => global)
      else
        I18n.t("reports.#{sub_report_code_stack.last}.#{key}", :default => global)
      end
    end
  end
end
