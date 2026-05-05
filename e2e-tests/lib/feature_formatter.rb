# frozen_string_literal: true

# Right-aligned Gherkin step keyword indentation:
#   step text starts at column 11 in every step line.
#   Given (5)+space → 4 leading spaces
#   When  (4)+space → 5 leading spaces
#   Then  (4)+space → 5 leading spaces
#   And   (3)+space → 6 leading spaces
#   But   (3)+space → 6 leading spaces
#   *     (1)+space → 6 leading spaces
class FeatureFormatter
  SECTION_INDENT = {
    'Feature' => 0,
    'Rule' => 2,
    'Background' => 2,
    'Scenario' => 2,
    'Scenario Outline' => 2,
    'Scenario Template' => 2
  }.freeze

  STEP_INDENT = {
    'Given' => 4,
    'When' => 5,
    'Then' => 5,
    'And' => 6,
    'But' => 6,
    '*' => 6
  }.freeze

  TAG_INDENT = 2

  SECTION_RE = /\A\s*(Feature|Rule|Background|Scenario Outline|Scenario Template|Scenario|Examples)\s*:.*\z/
  STEP_RE    = /\A\s*(Given|When|Then|And|But|\*)\s+(.*)\z/
  TABLE_RE   = /\A\s*(\|.*)\z/
  TAG_RE     = /\A\s*(@.*)\z/

  def self.feature_paths(root)
    Dir.glob(File.join(root, 'staff_features/**/*.feature'))
       .reject { |p| File.basename(p).start_with?('.#') }
  end

  def self.format(source)
    new.format(source)
  end

  def initialize
    @owner_indent = nil
    @prev_indent = nil
  end

  def format(source)
    source.lines.map { |raw| format_line(raw) }.join
  end

  private

  def format_line(raw)
    line = raw.chomp
    newline = raw.end_with?("\n") ? "\n" : ''

    return newline if line.strip.empty?
    return format_section(Regexp.last_match, line, newline) if SECTION_RE.match(line)
    return format_step(Regexp.last_match, newline) if STEP_RE.match(line)
    return format_table(Regexp.last_match, newline) if TABLE_RE.match(line)
    return format_tag(Regexp.last_match, newline) if TAG_RE.match(line)

    raw
  end

  def format_section(match, line, newline)
    kw = match[1]
    rest = line.sub(/\A\s*#{Regexp.escape(kw)}/, '')
    indent = kw == 'Examples' ? (@prev_indent || 4) + 2 : SECTION_INDENT[kw]
    @owner_indent = kw == 'Examples' ? indent : nil
    @prev_indent = indent
    "#{' ' * indent}#{kw}#{rest}#{newline}"
  end

  def format_step(match, newline)
    kw = match[1]
    indent = STEP_INDENT[kw]
    @owner_indent = indent
    @prev_indent = indent
    "#{' ' * indent}#{kw} #{match[2]}#{newline}"
  end

  def format_table(match, newline)
    indent = (@owner_indent || 4) + 2
    @prev_indent = indent
    "#{' ' * indent}#{match[1]}#{newline}"
  end

  def format_tag(match, newline)
    @prev_indent = TAG_INDENT
    "#{' ' * TAG_INDENT}#{match[1]}#{newline}"
  end
end
