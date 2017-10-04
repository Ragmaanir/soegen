require "json"

module Soegen
  # Stores a completed request, including the `HTTP::Request` as well as the `HTTP::Client::Response`
  class CompletedRequest
    getter response, request
    delegate method, path, host, to: request
    delegate status_code, body, to: response

    def initialize(@request : HTTP::Request, @response : HTTP::Client::Response)
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
