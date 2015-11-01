module Soegen
  class Index
    getter server, name

    def initialize(@server : Server, @name : String)
    end

    def exists?
      request(:head).ok_ish?
    end

    def create(options)
      request(:put, body: options.to_json)
    end

    def delete
      request(:delete)
    end

    def type(name : String)
      IndexType.new(self, name)
    end

    private def request(method : Symbol, path = "" : String, params={} of String => String, body = "" : String)
      path = "#{name}/#{path}"
      server.request(method, path, params, body)
    end
  end
end
