require "json"

module Soegen
  # Stores a completed request, including the `HTTP::Request` as well as the `HTTP::Client::Response`
  class CompletedRequest
    getter response : HTTP::Client::Response
    getter request : HTTP::Request
    delegate method, path, host, to: request
    delegate status_code, body, to: response

    def initialize(@request, @response)
    end

    def ok_ish?
      (200..299).includes?(status_code)
    end

    def json
      @json ||= parse_response
    end

    private def parse_response
      JSON.parse(response.body)
    end
  end
end
