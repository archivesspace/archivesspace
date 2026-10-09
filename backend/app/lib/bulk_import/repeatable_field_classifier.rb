require "set"

class RepeatableFieldClassifier
  Classification = Struct.new(
    :original, :representative, :namespace, :index, :relative_path,
    :inner_key, :inner_index, :inner_path,
    keyword_init: true
  ) do
    def nested?
      !inner_path.nil?
    end

    def nested_path
      deeper = INNER_RECORD_PATTERN.match(inner_path)
      [inner_key, *(deeper ? [deeper[:namespace], deeper[:path]] : [inner_path])].map(&:to_sym)
    end
  end

  INNER_RECORD_PATTERN = /\A(?<namespace>.+?)_(?<index>[1-9]\d*)_(?<path>.+)\z/

  def initialize(vocabulary:, families:, headers:)
    @vocabulary = vocabulary.compact.to_set
    @families = families.map { |family| structural_pattern(family) }
    @classifications = {}
    @unknown = []

    headers.compact.each do |header|
      classification = classify(header)
      if classification
        @classifications[header] = classification
      else
        @unknown << header
      end
    end
  end

  def classify(header)
    code = header.to_s

    @families.each do |family|
      match = family[:pattern].match(code)
      next unless match

      representative = code[0...match.begin(:index)] + "1" + code[match.end(:index)..-1]
      next unless @vocabulary.include?(representative)

      return Classification.new(
        original: code,
        representative: representative,
        namespace: family[:namespace],
        index: match[:index].to_i,
        relative_path: match[:path],
        **inner_record(family[:namespace], match[:path])
      )
    end

    return nil unless @vocabulary.include?(code)

    Classification.new(original: code, representative: code)
  end

  def unknown_headers
    @unknown.dup
  end

  def groups(namespace)
    @classifications.values
      .select { |classification| classification.namespace == namespace }
      .group_by(&:index)
      .sort_by { |index, _columns| index }
  end

  def field_code(namespace, index, property, inner_key: nil)
    representative = vocabulary_classifications.find do |classification|
      classification.namespace == namespace &&
        classification.inner_key == inner_key &&
        (inner_key ? classification.inner_path : classification.relative_path) == property
    end
    return nil unless representative

    representative.representative.sub(/\A#{Regexp.escape(namespace)}_1_/, "#{namespace}_#{index}_")
  end

  private

  def vocabulary_classifications
    @vocabulary_classifications ||= @vocabulary.filter_map do |code|
      classification = classify(code)
      classification if classification&.namespace
    end
  end

  def inner_record(namespace, path)
    match = INNER_RECORD_PATTERN.match(path)
    return {} unless match

    {
      inner_key: match[:namespace].delete_prefix("#{namespace}_"),
      inner_index: match[:index].to_i,
      inner_path: match[:path],
    }
  end

  def structural_pattern(family)
    path_prefix = family[:fixed_segment] ? "#{Regexp.escape(family[:fixed_segment])}_" : ""

    {
      namespace: family[:namespace],
      pattern: /\A#{Regexp.escape(family[:namespace])}_(?<index>[1-9]\d*)_(?<path>#{path_prefix}.+)\z/,
    }
  end
end
