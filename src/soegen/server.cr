require "uri"
require "http/client"
require "logger"

module Soegen

  class RequestError < Exception
    def initialize(@response : CompletedRequest)
      super("Request failed: #{response.request.method} #{response.request.path} with #{response.status_code} #{response.body}")
    end
  end

  VERBS = %w{GET POST PUT HEAD DELETE}

  class Server < Component

    REQUEST_HEADERS = {
      "accept" => "application/json",
      "user_agent" => "Soegen #{Soegen::VERSION}",
      "Content-Type" => "application/json"
    }

    getter client, logger

    def initialize(uri = "http://localhost:9200" : String, *args)
      parsed = URI.parse(uri)
      initialize(parsed.host.not_nil!, parsed.port.not_nil!, parsed.scheme == "https", *args)
    end

    def initialize( host : String,
                    port : Int32,
                    ssl = false : Bool,
                    read_timeout = 2.seconds : Time::Span,
                    connect_timeout = 5.seconds : Time::Span,
                    logger= Logger.new(STDOUT) : Logger)
      client = HTTP::Client.new(host, port, ssl)
      client.connect_timeout = connect_timeout
      client.read_timeout = read_timeout
      initialize(client, logger)
    end

    def initialize(@client : HTTP::Client, @logger = Logger.new(STDOUT))
    end

    def request_callback(&@callback : (CompletedRequest, Timing) -> T)
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

    def bulk(data : Array(T))
      request!(:post, "_bulk", {} of String => String, data.map{ |e| e.to_json + "\n"}.join)
    end

    def request(method : Symbol, path, params={} of String => String, body = "" : String)
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
      scheme += "s" if client.ssl?
      "#{scheme}://#{client.host}:#{client.port}"
    end

    def server
      self
    end

    private def log_request(response, timing)
      str = "[%3dms] %3d: %s" % Tuple.new(
        timing.duration.milliseconds,
        response.status_code,
        to_curl(response.request)
      )

      log_debug(str)
    end

    private def params_to_query_params(hash : Hash(String,String))
      hash.map{ |k,v| "#{URI.escape(k)}=#{URI.escape(v)}" }.join("&")
    end

    private def to_curl(request : HTTP::Request)
      method = request.method
      path = request.path || ""
      params = request.query_params.to_s
      params = "?" + params if !params.empty?

      body = case request.body
        when nil, "" then ""
        else "-d '#{request.body}'"
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
