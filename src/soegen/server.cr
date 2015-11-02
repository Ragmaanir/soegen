require "uri"
require "http/client"
require "logger"

require "besked"

module Soegen

  VERBS = %w{GET POST PUT HEAD DELETE}

  class Server

    class RequestEvent < Besked::Event
      getter request, response, timing

      def initialize(@request, @response, @timing)
      end
    end

    class RequestError < Exception
      def initialize(@request : HTTP::Request, @response : Response)
        super("Request failed: #{request.method} #{request.path} with #{response.status_code} #{response.body}")
      end
    end

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

    def refresh
      request(:post, "_refresh")
    end

    def up?
      request(:get, "/").ok_ish?
    end

    def index(name : String)
      Index.new(self, name)
    end

    def stats
      request(:get, "_stats")
    end

    # def status
    #   request(:get, "_status")
    # end

    def bulk(data)
      request(:post, "_bulk", {} of String => String, data)
    end

    def search(json_query)
      response = request(:get, "_search", json_query)

      if !response.ok_ish?
        #raise RequestError.new(request, response)
        raise "aaa"
      end

      SearchResult.new(response)
    end

    def request(method : Symbol, path, params={} of String => String, body = "" : String)
      method = method.to_s.upcase
      raise ArgumentError.new("Invalid http verb: #{method}") unless VERBS.includes?(method)
      headers = HTTP::Headers.new
      headers.merge!(REQUEST_HEADERS)
      request = HTTP::Request.new(method, path, headers, body)

      timing, response = timed do
        raw_response = @client.exec(request)
        Response.new(raw_response)
      end

      logger.debug("[Soegen][#{timing.duration.milliseconds}ms] Request #{method} #{path}")
      Besked::Global.publish(Soegen::Server, "request", RequestEvent.new(request, response, timing))
      response
    end

    class Timing
      getter start_time, end_time

      def initialize(@start_time, @end_time)
      end

      def duration
        end_time - start_time
      end
    end

    private def timed(&block)
      start = Time.new
      result = yield
      Tuple.new(Timing.new(start, Time.new), result)
    end
  end

end
