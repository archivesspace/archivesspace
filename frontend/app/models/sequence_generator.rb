class SequenceGenerator

  def initialize(from, to, prefix, suffix, limit)
    @errors = []

    @from = from
    @to = to
    @prefix = prefix
    @suffix = suffix

    # limit the range to 1000 entries, unless the number of rows is provided
    @limit = (limit || 1000).to_i

    generate_range
  end


  def generate_range
    range = (@from..@to)
    values = range.take(@limit).map{|i| "#{@prefix}#{i}#{@suffix}"}

    {
      "size" => values.length,
      "limit" => @limit,
      "values" => values,
      "summary" => @limit ?
        I18n.t("rde.fill_column.sequence_summary_with_maxsize", :limit => @limit, :count => values.length) :
        I18n.t("rde.fill_column.sequence_summary", :count => values.length)
    }
  end


  def self.from_params(params)
    errors = []
    errors.push(I18n.t("rde.fill_column.sequence_from_required")) if params[:from].blank?
    errors.push(I18n.t("rde.fill_column.sequence_to_required")) if params[:to].blank?

    return {"errors" => errors} if errors.length > 0

    self.new(params[:from], params[:to], params[:prefix], params[:suffix], params[:limit]).generate_range
  end
end