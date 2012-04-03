require 'bundler/setup'
require 'rake-pipeline'
require 'rake-pipeline/middleware'
require "rack/streaming_proxy" # Don't forget to install the rack-streaming-proxy gem.

class NoCache
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env).tap do |status, header, body|
      headers["Cache-Control"] = "no-store"
    end
  end
end

use Rack::StreamingProxy do |request|
  # Insert your own logic here
  if request.path.start_with?("/bclegal")
    "http://localhost:1337#{request.path}"
  end
end

use Rake::Pipeline::Middleware, 'Assetfile' # This is the path to your Assetfile
run Rack::Directory.new('.') # This should match whatever your Assetfile's output directory is
