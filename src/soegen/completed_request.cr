require "json"

module Soegen
  class CompletedRequest
    getter response, request
    delegate method, request
    delegate path, request
    delegate status_code, response
    delegate body, response

    def initialize(@request : HTTP::Request, @response : HTTP::Response)
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
