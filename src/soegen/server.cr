require "uri"
require "http/client"
require "logger"

module Soegen
  class RequestError < Exception
    def initialize(@response : CompletedRequest)
      super("Request failed: #{response.request.method} #{response.request.path} with #{response.status_code} #{response.body}")
    end
  end

  VERBS = %w(GET POST PUT HEAD DELETE)

  class Server < Component
    REQUEST_HEADERS = {
      "accept"       => "application/json",
      "user_agent"   => "Soegen #{Soegen::VERSION}",
      "Content-Type" => "application/json",
    }

    UTC_TIMESTAMP_FORMAT = Time::Format.new("%FT%XZ")

    DEFAULT_LOG_FORMATTER = Logger::Formatter.new do |severity, datetime, progname, message, io|
      UTC_TIMESTAMP_FORMAT.format(datetime.to_utc, io)
      io << " " << Process.pid << " "
      io << severity.rjust(5) << " " << progname << " " << message
    end

    alias Callback = (CompletedRequest, Timing) ->

    getter client, logger
    getter callback : Callback?

    def initialize(uri : String = "http://localhost:9200", *args)
      parsed = URI.parse(uri)
      initialize(parsed.host.not_nil!, parsed.port.not_nil!, parsed.scheme == "https", *args)
    end

    def initialize(host : String,
                   port : Int32,
                   ssl : Bool = false,
                   read_timeout : Time::Span = 2.seconds,
                   connect_timeout : Time::Span = 5.seconds,
                   logger : Logger = Server.default_logger)
      client = HTTP::Client.new(host, port, ssl)
      client.connect_timeout = connect_timeout
      client.read_timeout = read_timeout
      initialize(client, logger)
    end

    def initialize(@client : HTTP::Client, @logger = Server.default_logger)
    end

    def self.default_logger : Logger
      l = Logger.new(STDOUT)
      l.formatter = DEFAULT_LOG_FORMATTER
      l
    end

    def request_callback(&@callback : Callback)
    end

    def refresh
      request!(:post, "_refresh")
    end

    def up?
      request(:get, "").ok_ish?
    rescue e : Errno
      false
    end

    def index(name : String)
      Index.new(self, name)
    end

    def stats
      request!(:get, "_stats")
    end

    def bulk(data : Array(T)) forall T
      request!(:post, "_bulk", {} of String => String, data.map { |e| e.to_json + "\n" }.join)
    end

    def request(method : Symbol, path, params = {} of String => String, body : String = "")
      method = method.to_s.upcase
      raise ArgumentError.new("Invalid http verb: #{method}") unless VERBS.includes?(method)
      headers = HTTP::Headers.new
      headers.merge!(REQUEST_HEADERS)
      request = HTTP::Request.new(method, path, headers, body)
      request.query = params_to_query_params(params)

      timing, response = timed do
        raw_response = @client.exec(request)
        CompletedRequest.new(request, raw_response)
      end

      log_request(response, timing)
      invoke_callback(response, timing)
      response
    end

    def uri
      scheme = "http"
      scheme += "s" if client.tls?
      "#{scheme}://#{client.host}:#{client.port}"
    end

    def server
      self
    end

    private def log_request(response, timing)
      str = "%3dms %3d : %s" % Tuple.new(
        timing.duration.milliseconds,
        response.status_code,
        to_curl(response.request)
      )

      log_debug(str)
    end

    private def params_to_query_params(hash : Hash(String, String))
      hash.map { |k, v| "#{URI.escape(k)}=#{URI.escape(v)}" }.join("&")
    end

    private def to_curl(request : HTTP::Request)
      method = request.method
      path = request.path || ""
      params = request.query_params.to_s
      params = "?" + params if !params.empty?

      body = case request.body.to_s
             when "" then ""
             else         "-d '#{request.body}'"
             end

      "curl -X#{method} #{join_path(uri, path)}#{params} #{body}"
    end

    private def invoke_callback(*args)
      if c = @callback
        c.call(*args)
      end
    end

    private def timed(&block)
      start = Time.new
      result = yield
      Tuple.new(Timing.new(start, Time.new), result)
    end

    def uri_path(path : String)
      path
    end

    private def log_debug(message)
      logger.debug(message, "Soegen")
    end
  end
end
