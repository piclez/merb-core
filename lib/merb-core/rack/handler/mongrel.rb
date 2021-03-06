require 'mongrel'
require 'stringio'

class Mongrel::HttpResponse
  NO_CLOSE_STATUS_FORMAT = "HTTP/1.1 %d %s\r\n".freeze
  def send_status_no_connection_close(content_length=@body.length)
    unless @status_sent
      write(NO_CLOSE_STATUS_FORMAT % [@status, Mongrel::HTTP_STATUS_CODES[@status]])
      @status_sent = true
    end
  end
end

module Merb
  module Rack
    module Handler
      class Mongrel < ::Mongrel::HttpHandler
        # Runs the server and yields it to a block.
        #
        # ==== Parameters
        # app<Merb::Rack::Application>:: The app that Mongrel should handle.
        # options<Hash>:: Options to pass to Mongrel (see below).
        #
        # ==== Options (options)
        # :Host<String>::
        #   The hostname on which the app should run. Defaults to "0.0.0.0"
        # :Port<Fixnum>:: The port for the app. Defaults to 8080.
        def self.run(app, options={})
          server = ::Mongrel::HttpServer.new(options[:Host] || '0.0.0.0',
                                             options[:Port] || 8080)
          server.register('/', ::Merb::Rack::Handler::Mongrel.new(app))
          yield server  if block_given?
          server.run.join
        end
  
        # ==== Parameters
        # app<Merb::Rack::Application>:: The app that Mongrel should handle.
        def initialize(app)
          @app = app
        end
        # ==== Parameters
        # request<Merb::Request>:: The HTTP request to handle.
        # response<HTTPResponse>:: The response object to write response to.
        def process(request, response)
          env = {}.replace(request.params)
          env.delete "HTTP_CONTENT_TYPE"
          env.delete "HTTP_CONTENT_LENGTH"
  
          env["SCRIPT_NAME"] = ""  if env["SCRIPT_NAME"] == "/"
  
          env.update({"rack.version" => [0,1],
                       "rack.input" => request.body || StringIO.new(""),
                       "rack.errors" => STDERR,
  
                       "rack.multithread" => true,
                       "rack.multiprocess" => false, # ???
                       "rack.run_once" => false,
  
                       "rack.url_scheme" => "http",
                       "rack.streaming" => true
                     })
          env["QUERY_STRING"] ||= ""
          env.delete "PATH_INFO"  if env["PATH_INFO"] == ""
  
          status, headers, body = @app.call(env)
  
          begin
            response.status = status.to_i
            headers.each { |k, vs|
              vs.each { |v|
                response.header[k] = v
              }
            }
            
            if Proc === body
              body.call(response)
            else  
              body.each { |part|
                response.body << part
              }
            end
            response.finished
          ensure
            body.close  if body.respond_to? :close
          end
        end
      end
    end
  end
end