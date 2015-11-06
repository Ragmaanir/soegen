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

    def refresh
      request!(:post, "_refresh")
    end

    def type(name : String)
      IndexType.new(self, name)
    end

    def search(hash)
      search(hash.to_json)
    end

    def search(json_query : String)
      response = request(:get, "_search", {} of String => String, json_query)
      if response.ok_ish?
        SearchResult.new(response)
      else
        raise RequestError.new(response)
      end
    end

    def request!(*args)
      response = request(*args)

      if !response.ok_ish?
        raise RequestError.new(response)
      end
    end

    def request(method : Symbol, path = "" : String, params={} of String => String, body = "" : String)
      path = "#{name}/#{path}"
      server.request(method, path, params, body)
    end
  end
end
