require 'rrtf'

class RtfGenerator

	attr_accessor :report, :content, :rtf, :generator

	def initialize(report_generator)
		@generator = report_generator
		@report = report_generator.report
		@content = report.get_content
		@rtf = RRTF::Document.new
	end
	
	def generate
		header
		rtf.page_break unless report.page_break
		content.each do |item|
			rtf.page_break if report.page_break
			content_item(item)
		end
		rtf
	end

	def header
		rtf.paragraph do |p|
			p.apply(
				'bold' => true,
				'font_size' => 72
			) << report.title
			p.line_break
			report.info.each do |key, value|
				p.apply(
					'bold' => true
				) << "#{t(key)}: " unless key.to_s[0] == '_'
				p << value.to_s
				p.line_break
			end
			p << "Report Generated at #{DateTime.now.strftime("%Y-%m-%d %H:%M %Z")}"
		end
	end

	def content_item(item)
		rtf.paragraph do |p|
			p.apply(
				'bold' => true,
				'font_size' => 48
			) << generator.identifier(item)
			content_attributes(p, item)
		end
	end

	def content_attributes(p, hash, indent = 0)
		p.line_break
		hash.each do |key, value|
			next unless value
			p.line_break if value.kind_of?(Array)
			p << "\t" * indent
			p.apply(
				'bold' => true
			) << "#{t(key)}: " unless key.to_s[0] == '_'
			if value.kind_of?(Array)
				p.line_break
				generator.rtf_subreport(value) do |value|
					value.each do |item|
						content_attributes(p, item, indent + 1)
					end
				end
			elsif value				
				p << value.to_s
				p.line_break
			end
		end
	end

	def t(key)
		@generator.t(key)
	end
end