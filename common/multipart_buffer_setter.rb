class MultipartBufferSetter

  def initialize(app)
    @app = app
  end

  def call(env)
    env.merge!(Rack::RACK_MULTIPART_BUFFER_SIZE => 1*1024*1024)
    @app.call(env)
  end

end
