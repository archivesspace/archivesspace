require 'java'

# java_import org.xhtmlrenderer.pdf.ITextRenderer

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
    if report.format == 'json'
      generate_json(file)
    elsif report.format == 'html'
      generate_html(file)
    elsif report.format == 'pdf'
      generate_pdf(file)
    else
      generate_csv(file)
    end
  end

  def generate_json(file)
    json = ASUtils.to_json(report.query)
    file.write(json)
  end

  def generate_html(file)
    file.write(do_render('report.erb'))
  end

  def generate_pdf(file)
    output_stream = java.io.FileOutputStream.new(file.path)
    xml = ASUtils.tempfile('html_report_')
    xml.write(clean_invalid_xml_chars(do_render('report.erb')))
    xml.close
    renderer = org.xhtmlrenderer.pdf.ITextRenderer.new

    renderer.set_document(java.io.File.new(xml.path))
    renderer.layout

    pdf = renderer.create_pdf(output_stream)

    xml.unlink
    output_stream.close

    pdf
  end

  def generate_csv(file); end

  def xml_clean(data)
    invalid_chars = {}
    invalid_chars['"'] = '&quot;'
    invalid_chars['&'] = '&amp;'
    invalid_chars["'"] = '&apos;'
    invalid_chars['<'] = '&lt;'
    invalid_chars['>'] = '&gt;'
    data.each do |item|
      next unless item.is_a?(Hash)
      item.each do |key, value|
        if value.is_a?(Array)
          item[key] = xml_clean(value)
        elsif value
          value.to_s.gsub!(/[#{invalid_chars.keys.join('')}]/) do |ch|
            invalid_chars[ch]
          end
        end
      end
    end
    data
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
    render = do_render('generic_sub_listing.erb')
    sub_report_code_stack.pop
    sub_report_data_stack.pop
    render
  end

  def show_in_list(value)
    sub_report_code_stack.push(value.pop)
    sub_report_data_stack.push(value)
    render = do_render('generic_sub_report_list.erb')
    sub_report_code_stack.pop
    sub_report_data_stack.pop
    render
  end

  def template_path(file)
    if File.exist?(File.join('app', 'views', 'reports', file))
      return File.join('app', 'views', 'reports', file)
    end

    StaticAssetFinder.new('reports').find(file)
  end

  def identifier(record)
    "#{t('identifier_prefix')} #{report.identifier(record)}" if report.identifier(record)
  end

  def t(key)
    if sub_report_code_stack.empty?
      I18n.t("reports.#{report.code}.#{key}")
    else
      I18n.t("reports.#{sub_report_code_stack.last}.#{key}")
    end
  end
end
