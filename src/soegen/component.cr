module Soegen
  abstract class Component
    abstract def uri_path(path : String) : String

    def search(hash)
      search(hash.to_json)
    end

    def search(json_query : String)
      response = request!(:get, "_search", {} of String => String, json_query)

      SearchResult.new(response)
    end

    def request(method : Symbol, path : String = "", params={} of String => String, body : String = "")
      server.request(method, uri_path(path), params, body)
    end

    def request!(*args)
      response = request(*args)

      if !response.ok_ish?
        raise RequestError.new(response)
      end

      response
    end

    private abstract def server : Server

    # Dont put a / at the end if child is empty, so that parameters can be appended with ?
    private def join_path(parent : String, child : String)
      if child.empty?
        parent
      else
        [parent,child].join("/")
      end
    end
  end
end
