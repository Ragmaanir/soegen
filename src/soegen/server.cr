require "uri"
require "http/client"
require "logger"

module Soegen

  VERBS = %w{
    GET
    POST
    PUT
    HEAD
    DELETE
  }

  class Server

    REQUEST_HEADERS = {
      "accept" => "application/json",
      "user_agent" => "Soegen #{Soegen::VERSION}",
      "Content-Type" => "application/json"
    }

    getter client, logger

    def initialize(uri = "http://localhost:9200" : String)
      parsed = URI.parse(uri)
      initialize(parsed.host.not_nil!, parsed.port.not_nil!, parsed.scheme == "https")
    end

    def initialize(host : String, port : Int32, ssl = false : Bool, *args)
      client = HTTP::Client.new(host, port, ssl)
      initialize(client, *args)
    end

    def initialize(@client : HTTP::Client, @logger = Logger.new(STDOUT))
      @client.before_request do |req|

      end
    end

    def request(method : Symbol, path, params={} of String => String, body = "" : String)
      method = method.to_s.upcase
      raise ArgumentError.new("Invalid http verb: #{method}") unless VERBS.includes?(method)
      headers = HTTP::Headers.new
      headers.merge!(REQUEST_HEADERS)
      response = Response.new(@client.exec(method, path, headers, body))
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

    def search(json_query)
      SearchResult.new(request(:get, "_search", json_query))
    end
  end

end
