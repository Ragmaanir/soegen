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

  # Represents the Elasticsearch server and provides basic methods to check whether the
  # server is `#up?`, to retrieve an `#index(String)` or to `refresh` all indices.
  # It is also possible to provide a `request_callback=(Callback)` which is invoked
  # for every request, so you can hook up your instrumentation which records
  # request status as well as the `Soegen::Timing`.
  class Server < Component
    # The default headers used on every request
    REQUEST_HEADERS = {
      "accept"       => "application/json",
      "user_agent"   => "Soegen #{Soegen::VERSION}",
      "Content-Type" => "application/json",
    }

    UTC_TIMESTAMP_FORMAT = Time::Format.new("%FT%XZ")

    DEFAULT_LOG_FORMATTER = Logger::Formatter.new do |severity, datetime, progname, message, io|
      UTC_TIMESTAMP_FORMAT.format(datetime.to_utc, io)
      io << " " << Process.pid << " "
      io << severity.to_s.rjust(5) << " " << progname << " " << message
    end

    # The type of the `#request_callback`
    alias Callback = (CompletedRequest, Timing) ->

    getter client : HTTP::Client
    getter logger : Logger
    getter request_callback : Callback?

    def initialize(uri : String = "http://localhost:9200", **args)
      parsed = URI.parse(uri)
      initialize(parsed.host.not_nil!, parsed.port.not_nil!, parsed.scheme == "https", **args)
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

    def initialize(@client, @logger = Server.default_logger)
    end

    def self.default_logger : Logger
      l = Logger.new(STDOUT)
      l.formatter = DEFAULT_LOG_FORMATTER
      l
    end

    def define_callback(&@request_callback : Callback)
    end

    def request_callback=(@request_callback : Callback)
    end

    def refresh
      request!(:post, "_refresh")
    end

    def up?
      request(:get, "").ok_ish?
    rescue
      false
    end

    def index(name : String) : Index
      Index.new(self, name)
    end

    def stats
      request!(:get, "_stats")
    end

    # Makes a `POST` requests to the `_bulk` endpoint of elasticsearch with
    # the data being the elements of the array converted to
    # JSON by invoking `Object#to_json` on each entry.
    def bulk(data : Array(T)) forall T
      request!(:post, "_bulk", {} of String => String, data.map { |e| e.to_json + "\n" }.join)
    end

    # def put(path, params = {} of String => String, body : String = "")
    #   request(:put, path, params, body)
    # end

    def put(path, *args, **kwargs)
      request(:put, *args, **kwargs)
    end

    # Makes a request to elasticsearch and makes sure that the configured UserAgent
    # is added to the headers, wrapping the result in a `Soegen::CompletedRequest`.
    # In addition it makes sure that the request is logged and that the configured
    # `#request_callback` is invoked with the request result and its timing information.
    def request(method : Symbol, path, params = {} of String => String, body : String = "") : CompletedRequest
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

    def server : Server
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
      hash.map { |k, v| "#{URI.encode_www_form(k)}=#{URI.encode_www_form(v)}" }.join("&")
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
      if c = request_callback
        c.call(*args)
      end
    end

    private def timed(&block)
      start = Time.local
      result = yield
      Tuple.new(Timing.new(start, Time.local), result)
    end

    def uri_path(path : String) : String
      path
    end

    private def log_debug(message)
      logger.debug(message, "Soegen")
    end
  end
end
