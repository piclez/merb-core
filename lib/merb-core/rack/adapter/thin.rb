require 'thin'
module Merb
  
  module Rack

    class Thin
      # start a Thin server on given host and port.
      
      # ==== Parameters
      # opts<Hash>:: Options for Thin (see below).
      #
      # ==== Options (opts)
      # :host<String>:: The hostname that Thin should serve.
      # :port<Fixnum>:: The port Thin should bind to.
      # :app<String>>:: The application name.
      def self.start(opts={})
        Merb.logger.info("Using Thin adapter")
        Merb.logger.flush
        server = ::Thin::Server.new(opts[:host], opts[:port], opts[:app])
        server.silent = true
        server.start!
      end
    end
  end
end