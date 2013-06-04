require 'useragent'

module BrowserSupport
  Browser = Struct.new(:browser, :version)

  def self.init
    @bronze_browsers = [
      Browser.new("Internet Explorer", "7.0"),
      Browser.new("Safari", "4"),
      Browser.new("Firefox", "4"),
      Browser.new("Opera", "15")
    ]

    @silver_browsers = [
      Browser.new("Internet Explorer", "9.0"),
      Browser.new("Firefox", "7"),
    ]

    @gold_browsers = [
      Browser.new("Chrome", "1"),
    ]
  end

  def self.bronze
    @bronze_browsers
  end

  def self.silver
    @silver_browsers
  end

  def self.gold
    @gold_browsers
  end

end

BrowserSupport::init