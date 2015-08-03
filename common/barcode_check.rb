class BarcodeCheck

  attr_reader :min, :max

  def initialize(repo_code)
    @min = 0
    @max = 255

    return if !AppConfig.has_key?(:container_management_barcode_length)

    cfg = AppConfig[:container_management_barcode_length]

    [:system_default, repo_code].each do |key|
      if cfg.has_key?(key)
        @min = cfg[key][:min].to_i if cfg[key].has_key?(:min)
        @max = cfg[key][:max].to_i if cfg[key].has_key?(:max)
      end
    end
  end


  def valid?(barcode)
    !barcode || (min..max).cover?(barcode.length)
  end

end
