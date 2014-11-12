class ASpaceCompressor


  java_import 'java.lang.ClassNotFoundException'

  def initialize(flavour)
    @flavour = flavour
    @initialized = false 
    @disabled = false 
  end


  def do_init
    return if @disabled 
    yui = Dir.glob(File.join(File.absolute_path(File.dirname(__FILE__)), "yui-compressor*jar")).first
    begin
      classloader = java.net.URLClassLoader.new([java.net.URL.new("file:#{yui}")].to_java(java.net.URL))
      @js_compressor = classloader.find_class("com.yahoo.platform.yui.compressor.JavaScriptCompressor")
      @css_compressor = classloader.find_class("com.yahoo.platform.yui.compressor.CssCompressor")
      @error_reporter = classloader.find_class("org.mozilla.javascript.ErrorReporter")
      @initialized = true
    rescue ClassNotFoundException
      @disabled = true
    end
  end


  def get_js_compressor(input)
    @js_compressor.getConstructor(java.io.Reader, @error_reporter).
                   newInstance(input, nil)
  end


  def get_css_compressor(input)
    @css_compressor.getConstructor(java.io.Reader).newInstance(input)
  end


  def compress(s, opts = {})
    
    do_init if !@initialized
    return s if @disabled # simply return the asset if the compressor is not available 
    

    output = java.io.StringWriter.new

    input = java.io.InputStreamReader.new(java.io.ByteArrayInputStream.new(s.to_java.get_bytes("UTF-8")))
    if @flavour == :js
      get_js_compressor(input).compress(output, -1, true, false, false, false)
    else
      get_css_compressor(input).compress(output, -1)
    end
    input.close

    output.to_s
  end
end
