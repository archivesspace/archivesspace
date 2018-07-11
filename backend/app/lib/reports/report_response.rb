require_relative 'csv_response'
require_relative 'json_response'
require_relative 'pdf_response'
require_relative 'html_response'
require 'erb'
require 'nokogiri'

class ReportResponse

  attr_accessor :report
  attr_accessor :base_url

  def initialize(report,  params = {}  )
    @report = report
    @params = params
  end

  def generate
    @params[:html_report] ||= proc {
      ReportErbRenderer.new(@report, @params).render("report.erb")
    }

    format = @report.format

    klass = Object.const_get("#{format.upcase}Response")
    klass.send(:new, @report, @params).generate
  end

end

class ReportErbRenderer

  include ERB::Util

  def initialize(report, params)
    @report = report
    @params = params
  end

  def layout?
    @params.fetch(:layout, true)
  end

  def t(key)
    h(I18n.t("reports.#{@report.code}.#{key}"))
  end

  def render(file)
    HTMLCleaner.new.clean(ERB.new( File.read(template_path(file)) ).result(binding))
  end

  def format_4part(s)
    unless s.nil?
      ASUtils.json_parse(s).compact.join('.')
    end
  end

  def text_section(title, value)
    # Sick of typing these out...
    template = <<EOS
        <section>
            <h3>%s</h3>
            %s
        </section>
EOS

    template % [h(title), preserve_newlines(h(value))]
  end

  def subreport_section(title, subreport, *subreport_args)
    # Sick of typing these out...
    template = <<EOS
        <section>
            <h3>%s</h3>
             %s
        </section>
EOS

    template % [h(title), insert_subreport(subreport, *subreport_args)]
  end

  def format_date(date)
    unless date.nil?
      h(date.to_s)
    end
  end

  def format_boolean(boolean)
    if boolean
      "Yes"
    else
      "No"
    end
  end

  def format_number(number)
    unless number.nil?
      h(sprintf('%.2f', number))
    end
  end

  def insert_subreport(subreport, params = {})
    # If `subreport` is a class, create an instance.  Otherwise, use the
    # supplied instance directly.  This gives the caller the opportunity to
    # construct their own object if desired, without being forced to do so in
    # every case.
    #
    subreport_instance = if subreport.is_a?(AbstractReport)
      sureport
    elsif subreport.is_a?(Class)
      @report.new_subreport(subreport, params)
    else
      raise "insert_subreport expects first argument to be a Class or an AbstractReport"
    end

    ReportResponse.new(subreport_instance, :layout => false).generate
  end

  def transform_text(s)
    return '' if s.nil?

    # The HTML to PDF library doesn't currently support the "break-word" CSS
    # property that would let us force a linebreak for long strings and URIs.
    # Without that, we end up having our tables chopped off, which makes them
    # not-especially-useful.
    #
    # Newer versions of the library might fix this issue, but it appears that the
    # licence of the newer version is incompatible with the current ArchivesSpace
    # licence.
    #
    # So, we wrap runs of characters in their own span tags to give the renderer
    # a hint on where to place the line breaks.  Pretty terrible, but it works.
    #
    if @report.format === 'pdf'
      escaped = h(s)

      # Exciting regexp time!  We break our string into "tokens", which are either:
      #
      #   - A single whitespace character
      #   - A HTML-escaped character (like '&amp;')
      #   - A run of between 1 and 5 letters
      #
      # Each token is then wrapped in a span, ensuring that we don't go too
      # long without having a spot to break a word if needed.
      #
      at_start_of_word = true

      escaped.scan(/[\s]|&.*;|[^\s]{1,5}/).map {|token|
        if token.start_with?("&") || token =~ /\A[\s]\Z/
          # Don't mess with &amp; and friends, nor whitespace
          at_start_of_word = (token == ' ')

          token
        else
          if at_start_of_word
            at_start_of_word = false
            "<span class=\"wordstart\">#{token}</span>"
          else
            "<span>#{token}</span>"
          end
        end
      }.join("")
    else
      h(s)
    end
  end

  def preserve_newlines(s)
    transform_text(s).gsub(/(?:\r\n)+/,"<br>");
  end

  def template_path(template_name)
    if File.exist?(File.join('app', 'views', 'reports', template_name))
      return File.join('app', 'views', 'reports', template_name)
    end

    StaticAssetFinder.new('reports').find(template_name)
  end

  class HTMLCleaner

    def clean(s)
      doc = Nokogiri::HTML(s)

      # Remove empty dt/dd pairs
      doc.css("dl").each do |definition|
        definition.css('dt, dd').each_slice(2) do |dt, dd|
          if dd.text().strip.empty?
            dt.remove
            dd.remove
          end
        end
      end

      # Remove empty dls
      doc.css("dl").each do |dl|
        if dl.text().strip.empty?
          dl.remove
        end
      end

      # Remove empty tables
      doc.css("table").each do |table|
        if table.css("td").empty?
          table.remove
        end
      end

      # Remove empty sections
      doc.css("section").each do |section|
        if section.children.all? {|elt| elt.is_a?(Nokogiri::XML::Comment) || elt.text.strip.empty? || elt.name == 'h3'}
          section.remove
        end
      end

      result = doc.to_xhtml(:save_with => 0)

      # Remove any spaces Nokogiri inserted between spans that are inter-word
      # breaks.  Avoids funny output like "event ually".
      result.gsub!('</span> <span>', '</span><span>')

      result
    end

  end

end
