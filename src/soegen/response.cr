require "json"

module Soegen
  class Response
    getter raw_response
    delegate status_code, raw_response
    delegate body, raw_response

    def initialize(@raw_response : HTTP::Response)
    end

    def ok_ish?
      (200..299).includes?(status_code)
    end

    def json
      @json ||= parse_response
    end

    private def parse_response
      JSON.parse(raw_response.body)
    end
  end
end
